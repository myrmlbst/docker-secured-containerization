# script with no persistence... no data is saved
docker run python:3.12-alpine python -c 'f="/data.txt";open(f, "a").write(f"Ran!\n");print(open(f).read())'
# output is always "Ran!"

# script with persistence... data is saved
docker run -v mydata:/data python:3.12-alpine python -c 'f="/data/data.txt";open(f, "a").write(f"Ran!\n");print(open(f).read())'
# output when called once: "Ran!"
# output when called twice "Ran! Ran!"