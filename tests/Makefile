TESTS = dps.scm  spec.scm  storage.scm  swmflrr.scm  uuid.scm  zmq.scm

all:

check:
	for f in $(TESTS); do gosh $$f; done >> ../test.log

clean:
	#rm -rf data.o @@server-data-dir@@lock *~

