const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl.zig");

pub fn main() !void {
    try glfw.init(.{});
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, mach-glfw!", null, null, .{}) catch |err| {
        std.log.err("Could not create window: {}", .{ err });
        return;
    };
    defer window.destroy();

    try glfw.makeContextCurrent(window);
    try gl.load({}, getOpenGlProcAddress);

    while (!window.shouldClose()) {
        handleInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT); 

        const vertices = [_]f32{
            -0.5, -0.5, 0.0,
            0.5, -0.5, 0.0,
            0.0,  0.5, 0.0
        };

        // Creates Vertex Array Object
        var vao: c_uint = undefined;
        gl.genVertexArrays(1, &vao);
        gl.bindVertexArray(vao);

        // Creates Vertex Buffer Object
        var vbo: c_uint = undefined;
        gl.genBuffers(1, &vbo);
        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);

        // Tells OpenGL how it should interpret vertex buffer data
        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
        gl.enableVertexAttribArray(0);

        const vertexShaderSource  = [_][*:0]const u8 {
        \\ #version 460
        \\ layout (location = 0) in vec3 aPos;
        \\ void main() {
        \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        \\ }
        };
        
        const vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, 1, &vertexShaderSource, null);
        gl.compileShader(vertexShader);
        var success: c_int = undefined;
        gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
        var infoLog: [512]u8 = undefined;
        if (success == 0) {
            gl.getShaderInfoLog(vertexShader, 512, null, &infoLog);
            std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}", .{infoLog});
            break;
        }

        const fragmentShaderSource = [_][*:0]const u8 {
            \\ #version 460
            \\ out vec4 FragColor;
            \\ void main() {
            \\   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
            \\ }
        };
        const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, 1, &fragmentShaderSource, null);
        gl.compileShader(fragmentShader);

        const shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);
        gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
        if (success == 0) {
            gl.getProgramInfoLog(shaderProgram, 512, null, &infoLog);
            std.log.err("ERROR::SHADER::PROGRAM::COMPILATION_FAILED\n{s}", .{infoLog});
        }
        gl.useProgram(shaderProgram);

        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);

        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        try glfw.pollEvents();
        try window.swapBuffers();
    }
}

fn getOpenGlProcAddress(_: void, proc_name: [:0]const u8) ?*const anyopaque {
    if (glfw.getProcAddress(proc_name)) |proc| {
        return @ptrCast(*const anyopaque, proc);
    }
    return null;
}


fn handleInput(window: glfw.Window) void {
    if (window.getKey(.escape) == glfw.Action.press) {
        std.log.info("Closing after Escape pressed", .{});
        window.setShouldClose(true);
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
