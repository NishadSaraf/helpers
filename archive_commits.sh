author=("nishad.saraf"
	"nishads"
)
commits_dir=${PWD}/commits
repos=( "Xilinx/aie-rt"
	"amd/xdna-driver"
	"torvalds/linux"
	"Xilinx/linux-xlnx"
	"Xilinx/device-tree-xlnx"
	"Xilinx/plnx-aie-examples" "Xilinx/plnx-aie-examples" "Xilinx/plnx-aie-examples"
	"Xilinx/meta-petalinux"
)
branches=("xlnx_rel_v2022.1"
	  "main"
	  "master"
	  "master"
	  "master"
	  "rel-v2020.1" "rel-v2020.2" "rel-v2021.1"
	  "master"
)
component=("Userspace driver"
	   "AMD XDNA driver"
	   "Linux kernel"
	   "Linux kernel"
	   "Linux device tree generator"
	   "Petalinux application" "Petalinux application" "Petalinux application"
	   "Yocto"
)

pushd () {
	command pushd "$@" > /dev/null
}

popd () {
	command popd "$@" > /dev/null
}

flag_redundant_mds () {
	echo "[INFO]: Checking for redundant markdown files in ${commits_dir}"
	
	declare -A seen_commits
	local redundant_count=0
	local redundant_dir="$(dirname ${commits_dir})/redundant"
	
	pushd ${commits_dir} || return 1
	
	# Create redundant directory if needed
	mkdir -p "${redundant_dir}"
	
	# Process all markdown files
	for md_file in *.md; do
		[ -e "$md_file" ] || continue
		
		# Extract just the commit hash from the github URL
		local commit_hash=$(grep -o "github: 'https://github.com/.*/commit/[a-f0-9]*'" "$md_file" | grep -o '[a-f0-9]\{40\}')
		
		if [ -z "$commit_hash" ]; then
			continue
		fi
		
		# Check if we've seen this commit hash before (across any repo/fork)
		if [ -n "${seen_commits[$commit_hash]}" ]; then
			local original_file="${seen_commits[$commit_hash]}"
			echo "[WARN]: Redundant commit $commit_hash found in $md_file (duplicate of $original_file)"
			# Move redundant file to redundant directory
			mv "$md_file" "${redundant_dir}/"
			((redundant_count++))
		else
			# Mark this commit hash as seen
			seen_commits[$commit_hash]="$md_file"
		fi
	done
	
	if [ $redundant_count -gt 0 ]; then
		echo "[INFO]: Found and moved $redundant_count redundant markdown file(s) to ${redundant_dir}"
	else
		echo "[INFO]: No redundant markdown files found"
		rmdir "${redundant_dir}" 2>/dev/null
	fi
	
	popd
}

create_commit_mds () {
	# Extract org and repo name from org/repo format
	local org_repo="${1}"
	local repo_name=$(basename "${org_repo}")
	local org_name=$(dirname "${org_repo}")
	
	message="---%n"
	message+="date: '%as'%n"
	message+="title: \"%s\"%n"
	message+="github: 'https://github.com/${org_repo}/commit/%H'%n"
	message+="external: ''%n"
	message+="component: '${3}'%n"
	message+="company: '${org_name}'%n"
	message+="showInProjects: false%n"
	message+="---"

	if [ -d ${repo_name} ]; then
		echo "[INFO]: Repository ${repo_name} already exists, skipping clone"
	else
		echo "[INFO]: Cloning ${org_repo} from GitHub"
		git clone https://github.com/${org_repo}.git
		if [ ! -d ${repo_name} ]; then
			echo "[ERROR]: Failed to clone ${org_repo}, skipping"
			return 1
		fi
	fi
	echo "[INFO]: Entering ${PWD}/${repo_name} directory"
	pushd ${repo_name} || return 1
	echo "[INFO]: Fetching commits from ${2} branch of ${org_repo} repo"
	git fetch origin
	git reset --hard origin/${2}
	git --no-pager log --author=${4} --pretty="format:${message}" >   \
	    ${commits_dir}/log
	echo "[INFO]: Leaving ${PWD} directory"
	popd
	pushd ${commits_dir} || return 1
	split -d -l 9 log --additional-suffix=.md ${org_repo//\//_}_${2}_
	rm log
	echo "[INFO]: Leaving ${PWD} directory"
	popd
}

main () {
	rm -rf ${commits_dir}
	mkdir ${commits_dir}
	mkdir -p repo
	echo "[INFO]: Entering ${PWD}/repo directory"
	pushd repo
	for ((r = 0; r < ${#repos[@]}; r++ ));
	do
		for ((a = 0; a < ${#author[@]}; a++ ));
		do
			create_commit_mds ${repos[$r]} ${branches[$r]}	\
			"${component[$r]}" "${author[$a]}"
		done
	done
	echo "[INFO]: Leaving ${PWD} directory"
	popd
	if [ -d misc_commits ] && [ "$(ls -A misc_commits)" ]; then
		echo "[INFO]: Copying misc_commits to ${commits_dir}"
		cp -r misc_commits/* ${commits_dir}
	fi
	
	# Flag and move redundant markdown files
	flag_redundant_mds
}

main
