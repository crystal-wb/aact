ActionDispatch::Request.parameter_parsers = ActionDispatch::Request.parameter_parsers.except(:json)
# ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete(Mime::XML)

# original_parsers = ActionDispatch::Request.parameter_parsers
# xml_parser = -> (raw_post) { Hash.from_xml(raw_post) || {} }
# new_parsers = original_parsers.merge(xml: xml_parser)
# ActionDispatch::Request.parameter_parsers = new_parsers
