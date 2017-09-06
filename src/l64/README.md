# Converting c.o into c.so

```sh
curl https://raw.githubusercontent.com/KxSystems/kdb/master/l64/c.o -O
gcc -shared -fPIC c.o -o c.so
```
