--gc:arc

when not defined(fauTests):
  --d:strip
  --d:danger
  --d:lto

switch("define", "ThreadPoolSize=32")