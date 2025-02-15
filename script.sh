#!/usr/bin/env bash

function validate_file {
	declare -r file="${1}"

	if [[ ! -f "${default_file}" ]]; then
		printf "\x1b[38;5;196m[ERROR]\x1b[0m Arquivo inexistente: O arquivo '${default_file}' nao foi encontrado no diretorio atual.\n"
		exit 1

	elif [[ ! -s "${default_file}"  ]]; then
		printf "\x1b[38;5;196m[ERROR]\x1b[0m Arquivo vazio: O arquivo  '${default_file}' esta vazio.\n"
		exit 1

	fi

}

function check_status {
	declare -rl site="${1}"
	declare -r status_code=$(curl --output /dev/null --silent --head --write-out "%{http_code}" "${site}")

	if [[ "${status_code}" == "000" ]]; then
		printf "\x1b[38;5;196m[FAIL]\x1b[0m\t??? ${site}\n"
	else
		printf "\x1b[38;5;82m[OK]\x1b[0m\t${status_code} ${site}\n"
	fi
}

function run_checker {
	declare -i  running_jobs=0
	declare -ir cores=$(("$(nproc)"))

	if [[ -t 0  ]]; then
		while [[ $# > 0   ]]; do
			check_status "$1" &
			((running_jobs++))
			shift
			if [[ running_jobs > $cores  ]]; then
				running_jobs=0
			fi
		done
		wait
	else
		while IFS='\n' read -r line || [ -n "${line}" ]; do
			check_status "${line}" &
			((running_jobs++))
			if [[ running_jobs > $cores ]]; then
				wait
				running_jobs=0
			fi
		done
		wait
	fi
}

function check_requirements {
	if [[ ! $(which curl) ]]; then
		printf "\x1b[38;5;196m[ERROR]\x1b[0m Requisito inexistente: Comando 'curl' nao encontrado.\n"
		exit 1
	elif [[ ! $(which nproc) ]]; then
		printf "\x1b[38;5;196m[ERROR]\x1b[0m Requisito inexistente: Comando 'nproc' nao encontrado.\n"
		exit 1
	fi
}

function main {

	declare -- default_file="sites.txt"
	declare -- using_args=false
	declare -a args_list=()

	check_requirements 

	while [[ $# > 0 ]]; do
		case "$1" in
			-f|--file)
				shift
				default_file="${1}"
				break
				;;
			*)
				using_args=true
				args_list+=("${1}")
				shift
				;;
		esac
	done

	if [[ -t 0  ]];then
		if [[ "$using_args" == false  ]]; then
			validate_file "${default_file}"
			run_checker < "${default_file}"
			exit 0
		fi
	fi
	run_checker "${args_list[@]}"

}

main "${@}"

