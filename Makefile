GOSH = gosh

all:

check:
	@rm -f test.record test.log
	cd tests; GAUCHE_TEST_RECORD_FILE=../test.record $(MAKE) check
	@cat test.record

clean:
	cd tests; $(MAKE) clean
	rm -rf test.record *.log *~
