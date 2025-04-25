#!/bin/bash

prompt="nmapmate > "
module=""
target=""
options=()
selected_scripts=()
ports=()

update_prompt() {
    prompt="nmapmate"

    if [[ -n "$target" ]]; then
        prompt+=" [target: $target]"
    fi
    if [[ -n "${ports[*]}" ]]; then
        if [[ ${#ports[@]} -gt 5 ]]; then
            prompt+=" ports (${#ports[@]})"
        else
            prompt+=" ports($(
                IFS=','
                echo "${ports[*]}"
            ))"
        fi
    fi
    if [[ -n "${options[*]}" ]]; then
        if [[ ${#options[@]} -gt 5 ]]; then
            prompt+=" options(${#options[@]})"
        else
            prompt+=" options($(
                IFS=','
                echo "${options[*]}"
            ))"
        fi
    fi
    if [[ -n "${selected_scripts[*]}" ]]; then
        if [[ ${#selected_scripts[*]} -gt 3 ]]; then
            prompt+=" scripts(${#selected_scripts[@]})"
        else
            prompt+=" scripts(${selected_scripts[*]})"
        fi
    fi
    prompt+=" >  "
}

show_option() {

    printf "%-15s %-25s %-5s\n" "Name" "Current Setting" "Required"
    printf "%-15s %-25s %-5s\n" "-----" "--------------" "---------"
    printf "%-15s %-25s %-5s\n" "target" "$target" "yes"
    printf "%-15s %-25s % 0s\n" "ports" "${ports[*]}" "no"
    printf "%-15s %-25s %-5s\n" "options" "${options[*]}" "no"


    for script in "${selected_scripts[@]}"; do
        printf "%-15s %-30s\n" "script" "$script"
    done
}

run_scan() {
    if [[ -z "$target" ]]; then
        echo -e "\e[31m[!] Please set a target first.\e[0m"
        return
    fi
    # إعداد الأمر النهائي
    nmap_args=("nmap")
    if [[ -n "${options[*]}" ]]; then
        nmap_args+=("${options[@]}")
    fi
    if [[ -n "${selected_scripts[*]}" ]]; then
        echo "11"
        script_arg=$(IFS=,; echo "${selected_scripts[*]}")
        nmap_args+=("--script" "$script_arg")
    fi
    if [[ -n "${ports[*]}" ]]; then
        port_arg=$(IFS=,; echo "${ports[*]}")
        nmap_args+=("-p" "$port_arg")
    fi
    nmap_args+=("$target")
    echo -e "\e[36m🔍 Running:\e[0m ${nmap_args[@]}"
    echo -e "\e[33m[+] Scan started...\e[0m"
    echo
    nmap_args+=("--stats-every" "5s")
    temp_file=$(mktemp)
    sudo "${nmap_args[@]}" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ([0-9]+\.[0-9]+)%.*ETC.*([0-9]+\:[0-9]+) ]]; then
            percent="${BASH_REMATCH[1]}"
            eta="${BASH_REMATCH[2]}"
            echo -e "\e[34m⏳ Progress:\e[0m ${percent}%  |  ETA: ${eta} remaining"
        else
            echo "$line" >> "$temp_file"
        fi
    done
    clear
    echo
    echo -e "\e[32m[✔] Scan completed. Results:\e[0m"
    echo "--------------------------------------------"
    cat "$temp_file"
    echo "--------------------------------------------"

    rm -f "$temp_file"
}


while true; do
    echo -n "$prompt"
    read -r -a input_parts
    command="${input_parts[0]}"
    args="${input_parts[@]:1}"
    case "$command" in
    search)
        mapfile -t script_paths < <(find /usr/share/nmap/scripts/ -name "$args*")
        if [ ${#script_paths[@]} -eq 0 ]; then
            echo "⚠️ No Nmap scripts found starting with \"$args\". Exiting..."
        else
            printf "%s %-42s %-10s\n" " #" "Name" "Description"
            printf "%s %-42s %-10s\n" " -" "----" "-----------"
            echo
            for i in "${!script_paths[@]}"; do
                script_name=$(basename "${script_paths[$i]}")
                description=$(awk '
                        /description = \[\[/,/\]\]/ {
                            if (!found && $0 ~ /description = \[\[/) {
                                found = 1; next
                            }
                            if ($0 ~ /Reference:/ || $0 ~ /References:/) exit
                            if (found && $0 ~ /\]\]/) exit
                            if (found) print
                        }
                    ' "${script_paths[$i]}" | paste -sd " " - | sed 's/^[ \t]*//;s/[ \t]*$//')

                wrapped_desc=$(echo "$description" | fold -s -w 80)
                first_line=true
                while IFS= read -r line; do
                    if $first_line; then
                        printf "%2d) %-40s %s\n" $((i + 1)) "$script_name" "$line"
                        first_line=false
                    else
                        printf "    %-40s %s\n" "" "$line"
                    fi
                done <<<"$wrapped_desc"
                echo
            done
        fi
        ;;
    set)
        word_count=$(echo "$args" | wc -w)
        if [[ $word_count -gt 1 ]]; then
            key=$(echo "$args" | awk '{print $1}')
            value=$(echo "$args" | cut -d' ' -f2-)
            case "$key" in
            target)
                if [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ || "$value" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                    target="$value"
                    echo -e "target => \e[32m $target \e[0m"
                    update_prompt
                else
                    echo "❌ Invalid target format! Use IP, CIDR, or domain (e.g., 192.168.1.1 or google.com)"
                fi
                ;;
            option)
                echo "options => $target"
                for option in $value; do
                    options+=("$option")
                done
                update_prompt
                ;;
            port)
                selected_port=()
                for port in $value; do
                    if [[ "$port" =~ ^[0-9]+$ ]]; then
                        selected_port+=("$port")
                    else
                        echo "[-] The following options failed to validate: Value '$port' is not valid for option 'port'."
                    fi
                done
                ports+=("${selected_port[@]}")
                echo "=> $(
                    IFS=,
                    echo -e  "\e[32m${selected_port[*]} \e[0m"
                )"
                update_prompt
                ;;
            script)
                for script in $value; do
                    found=false
                    for existing in "${selected_scripts[@]}"; do
                        if [[ "$existing" == "$script" ]]; then
                            found=true
                            break
                        fi
                    done

                    if ! $found; then
                        selected_scripts+=("$script")
                    else
                        echo "[!] Script '$script' is already added."
                    fi
                done
                update_prompt
                ;;
            *) echo "Unknown setting: $key" ;;
            esac
        else
            echo  -e "[\e[31m*\e[0m] Valid parameters for the \"$args\""
        fi
        
        ;;
    unset)
        key=$(echo "$args" | awk '{print $1}')
        value=$(echo "$args" | cut -d' ' -f2-)
        case "$key" in
        target)
            if [[ -n "$target" ]]; then
                target=""
                update_prompt
            else
                echo "⚠️  there are no ip"
            fi
            ;;
        option)
            if [[ -n "${options[*]}" ]]; then
                if [[ "$value" =~ -|--?[a-zA-Z] ]]; then
                    for i in "${!options[@]}"; do
                        if [[ "${options[$i]}" == "$value" ]]; then
                            echo "Unsetting option"
                            unset 'options[i]'
                            update_prompt
                            break
                        else
                            echo "there no option \"$value\""
                        fi
                    done
                elif [[ "$value" == "all" ]]; then
                    echo "Unsetting option"
                    options=()
                    update_prompt
                fi
            else
                echo "⚠️  there are no options"
            fi
            ;;
        port)
            if [[ -n "${ports[*]}" ]]; then
                if [[ "$value" == "all" ]]; then
                    ports=()
                    echo "All ports removed."
                    update_prompt
                elif [[ "$value" =~ ^[0-9]+$ ]]; then
                    found=false
                    for i in "${!ports[@]}"; do
                        if [[ "${ports[$i]}" == "$value" ]]; then
                            echo "Unsetting port '$value'"
                            unset 'ports[i]'
                            update_prompt
                            found=true
                            break
                        fi
                    done
                    if ! $found; then
                        echo "⚠️port '$value' not found."
                    fi
                else
                    echo "❌ Invalid port format '$value'."
                fi
            else
                echo "⚠️ No ports to unset."
            fi
            ;;
        script)
            if [[ -n "${selected_scripts[*]}" ]]; then
                if [[ "$value" == "all" ]]; then
                    selected_scripts=()
                    echo "All scripts removed."
                    update_prompt
                else
                    found=false
                    for i in "${!selected_scripts[@]}"; do
                        if [[ "${selected_scripts[$i]}" == "$value" ]]; then
                            echo "Unsetting script '$value'"
                            unset 'selected_scripts[i]'
                            update_prompt
                            found=true
                            break
                        fi
                    done
                    if ! $found; then
                        echo "⚠️ No script named '$value' found."
                    fi
                fi
            else
                echo "⚠️ No scripts to unset."
            fi
            ;;
        *) echo "Unknown unset parameter: $key" ;;
        esac
        ;;
    run)
        run_scan
        ;;
    show)
        case "$args" in
            option)
                show_option
                ;;
            *)
                echo "Unknown command: $args"
                ;;
        esac
        ;;
    clear)
        clear
        ;;
    exit)
        # الخروج من البيئة
        echo "Goodbye!"
        break
        ;;
    help)
        # عرض الأوامر المتاحة
        printf "%-15s\n" "   "
        printf "%-15s\n" "Core Commands"
        printf "%-15s\n" "============="
        printf "%-15s\n" "   "

        printf "%-15s %-25s\n" "Command" "Description"
        printf "%-15s %-25s\n" "-------" "-----------"
        printf "%-15s %-25s\n" "help" "Help menu"
        printf "%-15s %-25s\n" "set" "Sets a context-specific variable to a value"
        printf "%-15s %-25s\n" "clear" "Clear the screen"
        printf "%-15s %-25s\n" "run" "To run "
        printf "%-15s %-25s\n" "exit" "Exit the console"

        printf "%-15s\n" "   "
        printf "%-15s %-25s\n" "script Commands"
        printf "%-15s\n" "==============="
        printf "%-15s\n" "   "
        printf "%-15s %-25s\n" "Command" "Description"
        printf "%-15s %-25s\n" "-------" "-----------"
        printf "%-15s %-25s\n" "search" "Searches scripts names"


        printf "%-15s\n" "   "
        ;;
    *)
        # أي أمر غير معروف
        echo "Unknown command: $command"
        ;;
    esac
done
