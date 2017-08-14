# Converting c.o into c.so

```sh
curl https://raw.githubusercontent.com/KxSystems/kdb/master/l32/c.o -O
gcc -m32 -shared -fPIC c.o -o c.so
```
