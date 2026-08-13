## Build with coq 8.9 usnig nix

Following the 2017 OCPL work, we use coq 8.9.x from 2019:

```
nix develop --command make -j"$(nproc)"
```
