module KdbMode
    import Base: LineEdit, REPL
    import Q._k: k, kj, kp
    using Q, Q.K_new, Q.chkparens

    const PROMPT = "q)"
    const PROMPT_COLOR = :light_blue
    const MODE_NAME = :q
    const MODE_KEY = '\\'

    function __init__()
        isdefined(Base, :active_repl) && install_kdb_mode(Base.active_repl)
    end

    function install_kdb_mode(repl)
        msg = String[]
        if Q.GOT_Q
            handle = 0
        else
            server_spec = get(ENV, "KDB", "")
            if isempty(server_spec)
                port, process = Q.Kdb.start()
                handle = hopen(port)
                atexit() do
                    rc = Q.Kdb.stop(handle, process)
                    info("Slave kdb+ exited with code $rc.")
                end
                push!(msg, "Connected to $port.")
            else
                try
                    handle = hopen(server_spec)
                    push!(msg, "Connected to $server_spec.")
                catch error
                    warn(repl.t.err_stream,
                         "Could not connect to $server_spec. $error")
                    handle = -1
                end
            end
        end
        if handle >= 0
            push!(msg, "Press '\\' for q) prompt.")
            install_kdb_mode(repl, handle)
            info(repl.t.err_stream, join(msg, " "))
            true
        else
            false
        end
    end

    function on_enter_do(prompt_state)
        !isempty(prompt_state) && begin
            chkparens(LineEdit.buffer(prompt_state).data) == 0
        end
    end

    function on_done_do_function(repl, handle)
        function(cmd)
            out = repl.t.out_stream
            x = K[]
            n = count(c == '\n' for c in cmd)
            size = max.([10, 0], Int[displaysize(out)...] - [n, 0])
            try
                x = K(k(handle, "{.Q.S[x-3 0;y;]value z}",
                        K_new(size), kj(0), kp("(::)"*cmd)))
            catch error
                if error isa KdbException
                    print_with_color(:red, out, "'", error.s)
                    println(out)
                else
                    println(out, error)
                end
            end
            for line in x
                println(out, line)
            end
        end
    end

    function create_kdb_panel(repl, handle)
        on_done_do = on_done_do_function(repl, handle)
        main_mode = repl.interface.modes[1]
        # Setup q) panel
        panel = LineEdit.Prompt(PROMPT;
            prompt_prefix=Base.text_colors[PROMPT_COLOR],
            prompt_suffix=Base.text_colors[:white],
            on_enter=on_enter_do)

        panel.on_done = REPL.respond(on_done_do, repl, panel)

        push!(repl.interface.modes, panel)

        hp = main_mode.hist
        hp.mode_mapping[MODE_NAME] = panel
        panel.hist = hp

        search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
        mk = REPL.mode_keymap(main_mode)

        b = Dict{Any,Any}[skeymap, mk,
                LineEdit.history_keymap,
                LineEdit.default_keymap,
                LineEdit.escape_defaults]
        panel.keymap_dict = LineEdit.keymap(b)

        panel
    end

    function install_kdb_mode(repl, handle)
        main_mode = repl.interface.modes[1]
        panel = create_kdb_panel(repl, handle)

        # Install this mode into the main mode
        q_keymap = Dict{Any,Any}(
            MODE_KEY => function (s, args...)
                if isempty(s) || position(LineEdit.buffer(s)) == 0
                    buf = copy(LineEdit.buffer(s))
                    LineEdit.transition(s, panel) do
                        LineEdit.state(s, panel).input_buffer = buf
                    end
                else
                    LineEdit.edit_insert(s, MODE_KEY)
                end
            end
        )
        LineEdit.keymap_merge!(main_mode.keymap_dict, q_keymap);
        nothing
    end
end
