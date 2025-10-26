/*
 * Find length of string
 *
 *
 *
 */
strlen(str)
    char *str;
{
    unsigned length;

    length = 0;
    while(*str++)
        ++length;
    return length;
}