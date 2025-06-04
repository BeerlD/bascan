FILE=bascan.sh
OUTPUT=bin/bascan
COMPILER=shc
FLAGS=-f

.PHONY: build clean all

build:
	@echo "\nBuilding..."
	@mkdir -p bin
	@$(COMPILER) $(FLAGS) $(FILE) -o $(OUTPUT)
	@rm -f $(FILE).x.c
	@echo "Done.\n"

clean:
	@rm -f $(OUTPUT) $(FILE).x.c

all: clean build
