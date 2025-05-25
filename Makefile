.PHONY: install

install:
	forge build
	forge install OpenZeppelin/openzeppelin-contracts --no-commit

foundry-test:
	forge test -vv