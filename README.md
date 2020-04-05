# Opium_kernel + Mirage

1. Install mirage - `opam install mirage`
2. Configure project.
    * For unix: `mirage configure -t unix`
    * For solo5: `mirage configure -t hvt` (follow network setup at https://github.com/Solo5/solo5/blob/master/docs/building.md#setting-up)
3. make depends (this installs all opam packages needed to build the server)
4. make
5. For unix, run it via `./main.native`. For solo5 `solo5-hvt --net:service=<network interface name from step 2> -- server.hvt`
