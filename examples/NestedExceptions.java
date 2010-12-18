package examples;

public class NestedExceptions {
	public NestedExceptions() {
		foo();
	}

	public void foo() {
		try {
			bar();
		} catch(Exception e) {
			throw new RuntimeException("foo error", e);
		}
	}

	public void bar() {
		try {
			baz();
		} catch(Exception e) {
			throw new RuntimeException("bar error", e);
		}
	}
	
	public void baz() {
		throw new RuntimeException("baz error");
	}
}