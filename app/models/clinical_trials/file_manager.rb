require 'action_view'
require 'open-uri'
include ActionView::Helpers::NumberHelper
module ClinicalTrials
  class FileManager

    def self.nlm_protocol_data_url
      "https://prsinfo.clinicaltrials.gov/definitions.html"
    end

    def self.nlm_results_data_url
      "https://prsinfo.clinicaltrials.gov/results_definitions.html"
    end

    def self.file_server
      '/var/local/share'
    end

    def file_server
      '/var/local/share'
    end

    def self.dump_directory
      "#{file_server}/tmp"
    end

    def dump_directory
      "#{file_server}/tmp"
    end

    def self.pg_dump_file
      "#{file_server}/tmp/postgres.dmp"
    end

    def self.static_copies_directory
      "#{file_server}/static_db_copies"
    end

    def self.flat_files_directory
      "#{file_server}/exported_files"
    end

    def self.snapshot_files
      files_in("static_db_copies")
    end

    def self.pipe_delimited_files
      files_in("exported_files")
    end

    def self.documentation_directory
      Rails.root.join('public','documentation')
    end

    def self.admin_schema_diagram
      "#{self.documentation_directory}/aact_admin_schema.png"
    end

    def self.schema_diagram
      "#{self.documentation_directory}/aact_schema.png"
    end

    def self.data_dictionary
      "#{self.documentation_directory}/aact_data_definitions.xlsx"
    end

    def self.table_dictionary
      "#{self.documentation_directory}/aact_tables.xlsx"
    end

    def self.default_data_definitions
      Roo::Spreadsheet.open(self.data_dictionary)
    end

    def self.default_mesh_terms
      "#{Rails.public_path}/mesh/mesh_terms.txt"
    end

    def self.default_mesh_headings
      "#{Rails.public_path}/mesh/mesh_headings.txt"
    end

    def self.get_file(params)
      file_name=params[:file_name]
      directory_name=params[:directory_name] ||= 'xml_downloads'
      File.open("#{file_name}", 'wb') { |out_file|
        s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
        s3.get_object({ bucket: ENV['S3_BUCKET_NAME'], key: "#{directory_name}/#{file_name}"}, target: out_file)
      }
      Zip::File.open(file_name)
    end

    def self.files_in(dir)
      entries=[]
      it=RestClient.get(file_server)
      doc=Nokogiri::XML(it)
      contents=doc.search('Contents')
      contents.each {|c|
        full_name=c.children.select{|c|c.name=='Key'}.first.children.text
        if !full_name.include?('archive')
          dir_and_file=full_name.split('/')
          last_modified=(c.children.select{|c|c.name=='LastModified'}.first.children.text).to_date.strftime('%Y-%m-%d')
          size=c.children.select{|c|c.name=='Size'}.first.children.text

          if dir_and_file.first == dir
            file_name=dir_and_file.last
            date_string=file_name.split('_').first
            date_created=(date_string.size==8 ? Date.parse(date_string).strftime("%m/%d/%Y") : date_string)
            file_url="#{file_server}/#{full_name}"
            entries << {:name=>dir_and_file.last,:date_created=>date_created,:size=>number_to_human_size(size), :url=>file_url}
          end
        end
      }
      entries.sort_by {|entry| entry[:name]}.reverse!
    end

    def self.db_log_file_content(params={:db_name=>'aact-prod'})
       db_name=params[:db_name]
       col=[]
       client = Aws::RDS::Client.new(region: ENV['AWS_REGION'])
       client.describe_db_log_files({:db_instance_identifier=>db_name}).data.describe_db_log_files.each{|file|
         begin
           file_name=file.log_file_name
           content=client.download_db_log_file_portion({:db_instance_identifier=>db_name, :log_file_name=>file_name})
           col << {:file_name => file_name, :content => content.data.log_file_data}
         rescue Exception => e
           entry={:file_name=>file_name, :log_time=> 'unknown', :content=>"#{Time.now} UTC: ERROR: #{e}\n"}
           col << entry
         end
       }
       col
    end

    def dump_database
      dump_file_name=self.class.pg_dump_file
      File.delete(dump_file_name) if File.exist?(dump_file_name)

      `PGPASSWORD=$RDS_DB_SUPER_PASSWORD pg_dump -h $RDS_DB_HOSTNAME -p 5432 -U $RDS_DB_SUPER_USERNAME --no-password --clean --exclude-table schema_migrations  -c -C -Fc -f  /var/www/aact/shared/tmp/postgres.dmp aact`
      return dump_file_name
    end

    def make_file_from_website(fname,url)
      return_file="#{file_server}/tmp/#{fname}"
      open(url) {|site|
        open(return_file, "wb"){|out_file|
            d=site.read
            out_file.write(d)
        }
      }
      return File.open(return_file)
    end

    def take_snapshot
      dump_database
      schema_diagram_file=File.open("#{self.class.documentation_directory}/aact_schema.png")
      admin_schema_diagram_file=File.open("#{self.class.documentation_directory}/aact_admin_schema.png")
      data_dictionary_file=File.open("#{self.class.documentation_directory}/aact_data_definitions.xlsx")
      nlm_protocol_file=make_file_from_website('nlm_protocol_definitions.html',self.class.nlm_protocol_data_url)
      nlm_results_file=make_file_from_website('nlm_results_definitions.html',self.class.nlm_results_data_url)

      zip_file_name="#{self.class.static_copies_directory}/#{Time.now.strftime('%Y%m%d')}_clinical_trials.zip"
      File.delete(zip_file_name) if File.exist?(zip_file_name)
      Zip::File.open(zip_file_name, Zip::File::CREATE) {|zipfile|
        zipfile.add('data_dictionary.xlsx',data_dictionary_file)
        zipfile.add('schema_diagram.png',schema_diagram_file)
        zipfile.add('admin_schema_diagram.png',admin_schema_diagram_file)
        zipfile.add('postgres_data.dmp',self.class.pg_dump_file)
        zipfile.add('nlm_protocol_definitions.html',nlm_protocol_file)
        zipfile.add('nlm_results_definitions.html',nlm_results_file)
      }
    end

  end
end
