# Raft

This is an implementation of the Raft consensus algorithm, in Elixir. 

## Running The Project

Parameters that can be directly configured in the `Makefile` include number of servers, number of clients and time to run the consensus algorithm for. All of the interesting experiments done (involving server crashes, changing election timeouts) are recorded in `configuration.ex`, and can be run using the `PARAMS` variable in the Makefile.

In order to start running the algorithm, run, in the root directory of the project:

```
make
```

Details and evaluation of any interesting experiments conducted are included in `report.pdf`. Corresponding outputs for experiments are present in the `outputs` directory.

## Acknowledgements
Skeleton was provided by Dr. Narenker Dulay, as part of his Imperial College Distributed Algorithms course. Implementation was done jointly by Dhruv Jimulia and Adi Prasad.