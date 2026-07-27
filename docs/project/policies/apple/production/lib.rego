package scanfair.apple.lib

import rego.v1

release_profile if {
	input.compliance_profile in {"release_candidate", "submission"}
}

submission_profile if {
	input.compliance_profile == "submission"
}

present(value) if {
	is_string(value)
	trim_space(value) != ""
}

https_url(value) if {
	present(value)
	starts_with_https(value)
}

starts_with_https(value) if {
	startswith(lower(value), "https://")
}
