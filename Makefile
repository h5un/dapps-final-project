.PHONY: install

install:
	forge build
	forge install OpenZeppelin/openzeppelin-contracts --no-commit