author="nishad.saraf"
commits_dir=${PWD}/commits
repos=( "embeddedsw"
	"linux-xlnx"
	"device-tree-xlnx"
	"plnx-aie-examples" "plnx-aie-examples" "plnx-aie-examples"
	"meta-petalinux"
)
branches=("master"
	  "master"
	  "master"
	  "rel-v2020.1" "rel-v2020.2" "rel-v2021.1"
	  "master"
)
component=("User-space/baremetal driver"
	   "Linux kernel"
	   "Linux device tree generator"
	   "Petalinux App" "Petalinux App" "Petalinux App"
	   "Yocto"
)

pushd () {
	command pushd "$@" > /dev/null
}

popd () {
	command popd "$@" > /dev/null
}

create_commit_mds () {
	message="---%n"
	message+="date: '%as'%n"
	message+="title: '%s'%n"
	message+="github: 'https://github.com/Xilinx/${1}/commit/%H'%n"
	message+="external: ''%n"
	message+="component: '${3}'%n"
	message+="company: 'Xilinx'%n"
	message+="showInProjects: false%n"
	message+="---"

	test -d ${1} || git clone https://github.com/Xilinx/${1}.git
	echo "[INFO]: Entering ${PWD}/${1} directory"
	pushd ${1}
	echo "[INFO]: Fetching commits from ${2} branch of ${1} repo"
	git fetch origin
	git reset --hard origin/${2}
	git --no-pager log --author=${author} --pretty="format:${message}" >   \
	    ${commits_dir}/log
	echo "[INFO]: Leaving ${PWD} directory"
	popd
	pushd ${commits_dir}
	split -d -l 10 log --additional-suffix=.md ${1}_${2}_
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
		create_commit_mds ${repos[$r]} ${branches[$r]} ${component[$r]}
	done
	echo "[INFO]: Leaving ${PWD} directory"
	popd
	cp -r misc_commits/* ${commits_dir}
}

main
