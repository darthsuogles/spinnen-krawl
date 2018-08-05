package y.phi9t.instrument;

import java.lang.instrument.Instrumentation;

public class ObjectSizeFetcher {
    //private static Instrumentation instrumentation;
    private static volatile Instrumentation globalInstr;

    public static void premain(String args, Instrumentation inst) {
        //instrumentation = inst;
        globalInstr = inst;
        System.out.println("[inst]: Agent initiated");
    }

    public static long getObjectSize(Object obj) {
        if (globalInstr == null)
            throw new IllegalStateException("Agent not initiated");
        return globalInstr.getObjectSize(obj);
    }
}
