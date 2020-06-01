module api

fn test_is_empty_str() {
	mut str := '     '
	assert api.is_empty_str(str) == true 
	
	str = '\a\b\t\n\v\f\r x'
	assert api.is_empty_str(str) == false

	str = '\a\b\t\n\v\f\r '
	assert api.is_empty_str(str) == true
}
