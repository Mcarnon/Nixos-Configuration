complete -c miyu -n __fish_use_subcommand -f -a ask -d 'Send a message to the assistant'
complete -c miyu -n __fish_use_subcommand -f -a init -d 'Create default config and state files'
complete -c miyu -n __fish_use_subcommand -f -a paths -d 'Show app config, data and cache paths'
complete -c miyu -n __fish_use_subcommand -f -a config -d 'Open or manage config'
complete -c miyu -n __fish_use_subcommand -f -a models -d 'List or switch models'
complete -c miyu -n __fish_use_subcommand -f -a fish-init -d 'Integrate with fish for natural language use in the terminal'
complete -c miyu -n __fish_use_subcommand -f -a bash-init -d 'Integrate with bash for natural language use in the terminal'
complete -c miyu -n __fish_use_subcommand -f -a zsh-init -d 'Integrate with zsh for natural language use in the terminal'
complete -c miyu -n __fish_use_subcommand -f -a remove-shell-hook -d 'Safely remove installed Miyu shell hook'
complete -c miyu -n __fish_use_subcommand -f -a history -d 'Show session history'
complete -c miyu -n __fish_use_subcommand -f -a kb -d 'Manage the local knowledge base'
complete -c miyu -n __fish_use_subcommand -f -a update-default-kb -d 'Update the Miyu default knowledge base'
complete -c miyu -n __fish_use_subcommand -f -a memory -d 'View or edit assistant memory'
complete -c miyu -n __fish_use_subcommand -f -a skills -d 'Manage assistant skills'
complete -c miyu -n __fish_use_subcommand -f -a reset -d 'Clear the current session history'

function __miyu_paste
    set -l output (miyu --clipboard-paste 2>/dev/null)
    if test $status -eq 0; and test -n "$output"
        if not set -q __miyu_image_counter
            set -g __miyu_image_counter 0
        end
        set __miyu_image_counter (math $__miyu_image_counter + 1)
        set output (string replace "Image 1" "Image $__miyu_image_counter" -- $output)
        commandline -i -- $output
        commandline -f repaint
    else
        fish_clipboard_paste
    end
end

bind \cv __miyu_paste

function __miyu_insert_newline
    commandline -f expand-abbr
    commandline -i \n
end

bind ctrl-j __miyu_insert_newline
bind \cj __miyu_insert_newline
bind -M insert ctrl-j __miyu_insert_newline
bind -M insert \cj __miyu_insert_newline

function __miyu_wrap_fish_prompt
    functions -q __miyu_original_fish_prompt; and return
    functions -q fish_prompt; or fish_prompt >/dev/null 2>/dev/null
    functions -q fish_prompt; or return

    functions -c fish_prompt __miyu_original_fish_prompt
    function fish_prompt
        if set -q __miyu_pending_buffer
            printf '\e[?25l'
        end
        __miyu_original_fish_prompt
    end
end

function __miyu_replay_buffer
    set -l buffer $argv[1]
    set -l lines (string split \n -- "$buffer")
    if test (count $lines) -gt 0
        set -l prompt (fish_prompt | string collect -N)
        set -l prompt_lines (string split \n -- "$prompt")
        set -l prompt_col (math (string length --visible -- "$prompt_lines[-1]") + 1)
        printf '\e[?25l'
        printf '\e[1A\e[%sG' $prompt_col
        if not set -q fish_color_error; or not set_color $fish_color_error 2>/dev/null
            set_color red
        end
        printf '%s\n' "$lines[1]"
        for line in $lines[2..-1]
            printf '  %s\n' "$line"
        end
        set_color normal
    end
end

function __miyu_restore_cursor
    printf '\e[?25h'
    set -e __miyu_cursor_hidden
end

function __miyu_on_prompt --on-event fish_prompt
    set -q __miyu_pending_buffer; or return

    set -l buffer $__miyu_pending_buffer
    set -e __miyu_pending_buffer
    set -e __miyu_image_counter

    trap __miyu_restore_cursor INT TERM EXIT
    __miyu_replay_buffer "$buffer"
    printf '%s' "$buffer" | miyu --shell-intercept --shell fish --stdin
    set -l miyu_status $status
    trap - INT TERM EXIT
    __miyu_restore_cursor
    return $miyu_status
end

function __miyu_execute_or_continue
    commandline --is-valid
    set -l valid_status $status
    if test $valid_status -eq 2
        commandline -i \n
        commandline -f repaint
    else
        set -e __miyu_image_counter
        commandline -f execute
    end
end

function __miyu_buffer_is_multiline
    test (string split \n -- "$argv[1]" | count) -gt 1
end

function __miyu_multiline_has_unknown_command
    set -l buffer $argv[1]
    for line in (string split \n -- "$buffer")
        set -l trimmed (string trim -- "$line")
        if test -z "$trimmed"; or string match -q '#*' -- "$trimmed"
            continue
        end

        set -l tokens (string split -n ' ' -- "$trimmed")
        while test (count $tokens) -gt 0
            set -l token $tokens[1]
            if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$token"
                set -e tokens[1]
                continue
            end
            break
        end
        set -l command $tokens[1]
        test -n "$command"; or continue
        type -q -- "$command"; or return 0
    end
    return 1
end

function __miyu_accept_line
    status is-interactive; or return

    commandline -f expand-abbr
    set -l buffer (commandline -b | string collect -N)
    set -l trimmed (string trim -- "$buffer")
    if test -z "$trimmed"
        __miyu_execute_or_continue
        return
    end

    if not __miyu_buffer_is_multiline "$buffer"
        __miyu_execute_or_continue
        return
    end

    if not __miyu_multiline_has_unknown_command "$buffer"
        __miyu_execute_or_continue
        return
    end

    set -e __miyu_image_counter
    __miyu_wrap_fish_prompt
    set -g __miyu_cursor_hidden 1
    history append -- "$buffer"
    set -g __miyu_pending_buffer "$buffer"
    commandline -b -- ""
    printf '\e[?25l'
    commandline -f execute
end

bind enter __miyu_accept_line
bind \r __miyu_accept_line
bind -M insert enter __miyu_accept_line
bind -M insert \r __miyu_accept_line

function fish_command_not_found
    status is-interactive; or return 127

    set -e __miyu_image_counter

    set -l command $argv
    if test (count $command) -eq 0
        return 127
    end

    set -l text (string join ' ' -- $command)
    string match -qr '[\n\r]' -- $text; and return 127

    miyu --shell-intercept --shell fish -- $command 2>/dev/null
    return 127
end
