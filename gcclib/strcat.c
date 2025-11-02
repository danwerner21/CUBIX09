void strcat(char *dest, char *src)
{
    int dest_len;
    int i;

    dest_len = strlen(dest);
    i = 0;

    while (src[i] != '\0')
    {
        dest[dest_len + i] = src[i];
        i++;
    }
    dest[dest_len + i] = '\0';
}
