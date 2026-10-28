import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import java.lang.classfile.*;
import java.lang.classfile.instruction.InvokeInstruction;
import java.lang.constant.*;
import org.lwjgl.glfw.GLFW;
import org.lwjglx.opengl.Display;

/** Test-process window policy. Render normally, but never show or focus the native window. */
public final class FocusAgent {
    private static boolean audited;

    public static void checkState(int visible, int focused) {
        if (visible != 0 || focused != 0) throw new IllegalStateException("PZ_TEST_FAIL native window visible/focused");
    }

    public static void auditWindow() {
        long window = Display.getWindow();
        if (window == 0) return;
        checkState(GLFW.glfwGetWindowAttrib(window, GLFW.GLFW_VISIBLE),
                   GLFW.glfwGetWindowAttrib(window, GLFW.GLFW_FOCUSED));
        if (!audited) {
            audited = true;
            System.out.println("PZ_TEST_HIDDEN_WINDOW_PASS pid=" + ProcessHandle.current().pid());
        }
    }

    public static void premain(String options, Instrumentation instrumentation) {
        checkState(0, 0);
        int caught = 0;
        for (int[] state : new int[][]{{1, 0}, {0, 1}}) {
            try { checkState(state[0], state[1]); }
            catch (IllegalStateException expected) { caught++; }
        }
        if (caught != 2) throw new IllegalStateException("Window guard negative controls failed");
        System.out.println("PZ_TEST_WINDOW_GUARD_PASS two negative controls, no visible window created");
        instrumentation.addTransformer(new ClassFileTransformer() {
            public byte[] transform(ClassLoader loader, String name, Class<?> type,
                                    ProtectionDomain domain, byte[] bytes) {
                if (!name.equals("org/lwjglx/opengl/Display")) return null;
                try {
                    var cf = ClassFile.of();
                    int[] suppressed = {0};
                    var transform = ClassTransform.transformingMethodBodies((builder, element) -> {
                        if (element instanceof InvokeInstruction call && call.owner().asInternalName().equals("org/lwjgl/glfw/GLFW")) {
                            if (call.name().stringValue().equals("glfwInit")) {
                                builder.loadConstant(GLFW.GLFW_COCOA_MENUBAR).iconst_0().invokestatic(
                                    ClassDesc.of("org.lwjgl.glfw.GLFW"), "glfwInitHint", MethodTypeDesc.ofDescriptor("(II)V"));
                            }
                            if (call.name().stringValue().equals("glfwCreateWindow")) {
                                for (int hint : new int[]{GLFW.GLFW_VISIBLE, GLFW.GLFW_FOCUSED, GLFW.GLFW_FOCUS_ON_SHOW}) {
                                    builder.loadConstant(hint).iconst_0().invokestatic(ClassDesc.of("org.lwjgl.glfw.GLFW"),
                                        "glfwWindowHint", MethodTypeDesc.ofDescriptor("(II)V"));
                                }
                            }
                            if (call.type().stringValue().equals("(J)V") &&
                                (call.name().stringValue().equals("glfwFocusWindow") || call.name().stringValue().equals("glfwShowWindow"))) {
                                builder.pop2(); suppressed[0]++; return;
                            }
                            if (call.name().stringValue().equals("glfwPollEvents")) {
                                builder.with(element).invokestatic(ClassDesc.of("FocusAgent"), "auditWindow",
                                    MethodTypeDesc.ofDescriptor("()V"));
                                return;
                            }
                        }
                        builder.with(element);
                    });
                    byte[] result = cf.transformClass(cf.parse(bytes), transform);
                    if (suppressed[0] < 3) throw new IllegalStateException("Installed Display window calls changed");
                    System.out.println("PZ_TEST_HIDDEN_PATCH show/focus calls suppressed=" + suppressed[0]);
                    return result;
                } catch (Throwable failure) {
                    // The JVM otherwise ignores transformer failures and could display an unpatched window.
                    failure.printStackTrace();
                    Runtime.getRuntime().halt(1);
                    return null;
                }
            }
        });
    }
}
