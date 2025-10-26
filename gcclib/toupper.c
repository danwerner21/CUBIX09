

char tolower(char c)
{
	char cb = c;
	if ((cb >= 'A') && (cb <= 'Z'))
		cb ^= 0x20;
	return cb;
}

char toupper(char c)
{
	char cb = c;
	if ((cb >= 'a') && (cb <= 'z'))
		cb ^= 0x20;
	return cb;
}

char islower(char c)
{
	return ((char)c >= 'a') && ((char)c <= 'z');
}

char isupper(char c)
{
	return ((char)c >= 'A') && ((char)c <= 'Z');
}


char isdigit(char c)
{
	return ((char)c >= '0') && ((char)c <= '9');
}

char isxdigit(char c)
{
	char bc = c;
	if (isdigit(bc))
		return 1;
	bc |= 0x20;
	return ((bc >= 'a') && (bc <= 'f'));
}

char isprint(char c)
{
	return ((char)c >= 32) && ((char)c <= 126);
}
