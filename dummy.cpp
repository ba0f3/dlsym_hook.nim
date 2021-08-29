#include <iostream>
#include <dlfcn.h>

typedef uint32_t random_function_t(const char*);

const char* g_encrypted_fn = "qtur";
const char* g_encrypted_str = "udru";

// xor string with key 0x1
char* decrypt(const char* encrypted, size_t encrypted_size) {
    char* ptr = (char*)malloc(encrypted_size + 1);

    for (int i = 0; i < encrypted_size; ++i) {
        ptr[i] = encrypted[i] ^ 1;
    }
    ptr[encrypted_size] = '\0';

    return ptr;
}

int main() {
    puts("-- test dlsym --");

    auto fn_name = decrypt(g_encrypted_fn, 4);
    auto fn_ptr = (random_function_t*)dlsym((void*)-1, fn_name);

    auto str = decrypt(g_encrypted_str, 4);
    fn_ptr(str);

    return 0;
}