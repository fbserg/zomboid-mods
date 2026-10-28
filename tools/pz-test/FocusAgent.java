import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import java.lang.classfile.*;
import java.lang.classfile.instruction.InvokeInstruction;
import java.lang.constant.*;

/** Test-only window policy. No game file or gameplay method changes. */
public final class FocusAgent {
    public static void premain(String options, Instrumentation instrumentation) {
        instrumentation.addTransformer(new ClassFileTransformer() {
            public byte[] transform(ClassLoader loader, String name, Class<?> type,
                                    ProtectionDomain domain, byte[] bytes) {
                if (!name.equals("org/lwjglx/opengl/Display")) return null;
                var cf = ClassFile.of();
                var transform = ClassTransform.transformingMethodBodies((builder, element) -> {
                    if (element instanceof InvokeInstruction call && call.owner().asInternalName().equals("org/lwjgl/glfw/GLFW")
                            && call.type().stringValue().equals("(J)V")) {
                        if (call.name().stringValue().equals("glfwFocusWindow")) { builder.pop2(); return; }
                        if (call.name().stringValue().equals("glfwShowWindow")) {
                            builder.dup2().loadConstant(131084).iconst_0().invokestatic(ClassDesc.of("org.lwjgl.glfw.GLFW"),
                                "glfwSetWindowAttrib", MethodTypeDesc.ofDescriptor("(JII)V"));
                        }
                    }
                    builder.with(element);
                });
                byte[] result = cf.transformClass(cf.parse(bytes), transform);
                System.out.println("PZ_TEST_NO_FOCUS_PATCH Display window policy installed");
                return result;
            }
        });
    }
}
