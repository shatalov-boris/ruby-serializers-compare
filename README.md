Original benchmark - https://github.com/okuramasafumi/alba/tree/main/benchmark

## Benchmark for json serializers

This directory contains a few different benchmark scripts. They all use inline Bundler definitions so you can run them
by `ruby benchmark/collection.rb` for instance.

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

| Key  | Value                                                             |
|------|-------------------------------------------------------------------|
| OS   | macOS 13.4                                                        |
| CPU  | Intel 2,6 GHz 6-Core Intel Core i7                                |
| RAM  | 16GB                                                              |
| Ruby | ruby 2.7.7p221 (2022-11-24 revision 168ec2b1e5) [x86_64-darwin22] |

Library versions:

| Library                  | Version |
|--------------------------|---------|
| alba                     | 2.2.0   |
| blueprinter              | 0.25.3  |
| jserializer              | 0.2.1   |
| oj                       | 3.14.2  |
| simple_ams               | 0.2.6   |
| representable            | 3.2.0   |
| turbostreamer            | 1.10.0  |
| jbuilder                 | 2.11.5  |
| panko_serializer         | 0.7.9   |
| active_model_serializers | 0.9.7   |
| jsonapi-serializer       | 2.2.0   |


`active_model_serializers` 0.9.7:

`benchmark-ips`

```
Comparison:
               panko:      276.9 i/s
       turbostreamer:      101.2 i/s - 2.74x  slower
                alba:       97.5 i/s - 2.84x  slower
         alba_inline:       97.0 i/s - 2.85x  slower
         jserializer:       78.9 i/s - 3.51x  slower
               rails:       76.2 i/s - 3.63x  slower
                 ams:       56.2 i/s - 4.93x  slower
         blueprinter:       43.7 i/s - 6.34x  slower
            json_api:       40.7 i/s - 6.80x  slower
       representable:       32.6 i/s - 8.49x  slower
          simple_ams:       26.5 i/s - 10.43x  slower
```

`benchmark-memory`:

```
Comparison:
               panko:     318418 allocated
       turbostreamer:     869008 allocated - 2.73x more
         jserializer:    1078105 allocated - 3.39x more
                alba:    1087273 allocated - 3.41x more
         alba_inline:    1102273 allocated - 3.46x more
         blueprinter:    1950537 allocated - 6.13x more
               rails:    2513561 allocated - 7.89x more
                 ams:    2774961 allocated - 8.71x more
            json_api:    2912857 allocated - 9.15x more
       representable:    3437158 allocated - 10.79x more
          simple_ams:    7291417 allocated - 22.90x more
```

`active_model_serializers` 0.10.13:

`benchmark-ips`

```
Comparison:
               panko:      171.9 i/s
                alba:      101.1 i/s - 1.70x  slower
       turbostreamer:       99.7 i/s - 1.72x  slower
         alba_inline:       94.8 i/s - 1.81x  slower
         jserializer:       72.4 i/s - 2.37x  slower
               rails:       59.9 i/s - 2.87x  slower
         blueprinter:       42.0 i/s - 4.09x  slower
            json_api:       31.5 i/s - 5.46x  slower
       representable:       27.2 i/s - 6.31x  slower
          simple_ams:       26.0 i/s - 6.60x  slower
                 ams:        9.1 i/s - 18.89x  slower
```

`benchmark-memory`:

```
Comparison:
               panko:     318418 allocated
       turbostreamer:     869008 allocated - 2.73x more
         jserializer:    1078105 allocated - 3.39x more
                alba:    1087273 allocated - 3.41x more
         alba_inline:    1102273 allocated - 3.46x more
         blueprinter:    1950537 allocated - 6.13x more
               rails:    2513561 allocated - 7.89x more
            json_api:    2912857 allocated - 9.15x more
       representable:    3437158 allocated - 10.79x more
                 ams:    5186847 allocated - 16.29x more
          simple_ams:    7291417 allocated - 22.90x more

```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, `turbostreamer`
and `jserializer` are notably faster than others, but Alba is slightly slower than other two.
