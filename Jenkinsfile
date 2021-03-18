import hudson.model.*;

pipeline {
    agent any
    environment {
        WORKSPACE_PATH = "${WORKSPACE}"
        SCRIPT_PATH = "${WORKSPACE}/script"
        ANSIBLE_PATH = "${WORKSPACE}/ansible"
        AGENTCONFIG_PATH = "${WORKSPACE}/conf"
        TEMP_PATH = "${WORKSPACE}/tmp"
    }
    stages {
        stage('prepareEnv') {
            steps {
                script {
                    echo "${SCRIPT_PATH}"
                    echo "${WORKSPACE}"
                    println env.workspace
                    dir("$ANSIBLE_PATH") {
                        git branch: "${branch}", url: "${url}"
                    }
                    yaml_string = """   
                                        stages:
                                        - stage: performancetest
                                          displayname: performancetest
                                          jobs:
                                          - job: S3testserver
                                            displayname: S3 performancetest on minio
                                            vms:
                                              vmsagentname: server
                                              vmsboxname: ubuntu
                                              vmsboxversion: 1604
                                              vmsipadd: 192.168.2.30,192.168.2.31,192.168.2.32,192.168.2.33
                                              vmsnodename: test1,test2,test3,test4
                                              vmsnum: 4
                                              vmsusername: root
                                              vmspassword: root123
                                            steps:
                                            - task: minio
                                              type: ansible
                                              displayname: install minio
                                              inputs:
                                                minio_server_datadirs: /minio-data
                                                minio_access_key: "1234567890"
                                                minio_secret_key: "1234567890"
                                            - task: sshkey
                                              type: ansible
                                              displayname: sshkey
                                            - task: S3_benchmark
                                              displayname: S3_benchmark
                                              inputs:
                                                command1: build
                                                command2: build1
                                            - script: RunShellCmdAllNode
                                              displayname: run touch command all node
                                              isparallel: true
                                              inputs:
                                                command1: touch 1223, sleep 10
                                                command2: touch 123123, sleep 10
                                                command3: touch 131232, sleep 10
                                            - script: RunShellCmdAllNode
                                              displayname: run touch command all node
                                              isparallel: false
                                              inputs:
                                                command1: touch 2222, sleep 10
                                                command2: touch 3333, sleep 10
                                                command3: touch 4444, sleep 10
                                          - job: S3testclient
                                            displayname: S3 performancetest on minio client
                                            vms:
                                              vmsagentname: client
                                              vmsboxname: centos
                                              vmsboxversion: 7.6
                                              vmsipadd: 192.168.2.34
                                              vmsnodename: client1
                                              vmsnum: 1
                                              vmsusername: root
                                              vmspassword: root123
                                            steps:
                                            - task: sshkey
                                              type: ansible
                                              displayname: sshkey
                                            - script: RunShellCmdAllNode
                                              displayname: run touch command all node
                                              isparallel: true
                                              inputs:
                                                command1: touch 1231, sleep 10
                                                command2: touch 2324, sleep 10
                                                command3: touch 4324, sleep 10
                                        - stage: buildtest
                                          displayname: 
                                        """
					read_yaml_file(yaml_string)
					def testki = readYaml text : yaml_string
                }
            }
        }
        
        stage('ExcuteTest') {
            steps {
                script {
                    echo "this is Test Stage"
                }
            }
        }
        
        stage("cleanup") {
            steps {
                script {
                    echo "this is clean up stage"
                }
            }
        }
    }
}

def RunAnsibleScript(String Cmd) {
    sh "/usr/local/bin/ansible-playbook ${WORKSPACE}/ansible/$Cmd --inventory-file=${WORKSPACE_PATH}/hosts" 
}

def RunShellCmdAllNode(Agentname, String Cmd) {
    def ansibledir = ANSIBLE_PATH + "/shell"
    def cmdtext = "\"" + Cmd + "\""
    println cmdtext
    VmsAgentCONFIGFile = Agentname
    sh "/usr/bin/bash ${ansibledir}/run.sh ${VmsAgentCONFIGFile} ${cmdtext}"
}

def RunShellScript(String Cmd) {
    RunShellScript("$Cmd", false)
}

def RunShellScript(String Cmd, boolean getReturn) {
    if (getReturn && getReturn == true) {
      sh(script: "/usr/bin/bash $Cmd", returnStdout: true).trim()
    } else {
      sh "/usr/bin/bash $Cmd"
    }
}

def PrepareVMSAgent(Stage, Job, VmsAgent) {
    println VmsAgent
    println Stage
    println Job
    def vms = [:] 
    def configtext = ""
    vms = VmsAgent
    VmsAgentCONFIGFile = Stage + "-" + Job + "-" + vms.vmsagentname + "-AGENTCONFIG"
    VmsAgentCONFIGFilePATH = AGENTCONFIG_PATH + "/" + VmsAgentCONFIGFile
    vms.each {
        configtext = configtext + it.key + "=" + it.value + "\n"
    }
    writeFile file: VmsAgentCONFIGFilePATH, text: configtext    
    RunShellScript("test.sh $VmsAgentCONFIGFile")
    
}

def CleanupVMSAgent(Stage) {
    RunShellScript("cleanup.sh $Stage")
}

def ExcuteTask(Stage, Job, VmsAgent, Task) {
    println Task
    def inputs = [:]
	def text = ""
	def vms = [:]
	vms = VmsAgent
    inputs = Task.inputs
    	
    if (Task.type ==~ "ansible")
    {
	    def ansibledir = ANSIBLE_PATH + "/" + Task.task
		inputs.each {
	        text = it.value + " " + text 
	    }
	    VmsAgentName = Stage + "-" + Job + "-" + vms.vmsagentname
	    VmsAgentCONFIGFile = VmsAgentName + "-AGENTCONFIG"
	    println VmsAgentCONFIGFile
        println text
        sh "/usr/bin/bash ${ansibledir}/run.sh ${VmsAgentCONFIGFile} ${text}"        
    }	
}

def ExcuteScript(Stage, Job, VmsAgent, Script) {
    def inputs = [:]
    def vms = [:]
	vms = VmsAgent
    VmsAgentName = Stage + "-" + Job + "-" + vms.vmsagentname
    VmsAgentCONFIGFile = VmsAgentName + "-AGENTCONFIG"
    inputs = Script.inputs
    if ( Script.script ==~ "RunShellCmdAllNode" && Script.isparallel ==~ "true")
    {
        def stepsForParallel = [:]
        inputs.each {
            stepsForParallel[it] = {
                node {
                    stage("${it}") {
                        try {
							def command = it.value.split(",")
							command.each {
							    println it
							    RunShellCmdAllNode("${VmsAgentCONFIGFile}", "${it}")
							}
                        } catch(exc) {
                            println exc
                        }
                    }
                }
            }
        }
        parallel stepsForParallel
    } else {
        inputs.each {
                node {
                    stage("${it}") {
                        try {
							def command = it.value.split(",")
							command.each {
							    println it
							    RunShellCmdAllNode("${VmsAgentCONFIGFile}", "${it}")
							}
                        } catch(exc) {
                            println exc
                        }
                                    
                    }
                }
			}
        }
}

def read_yaml_file(yaml_file) {
	def datas = ""
	if(yaml_file.toString().endsWith(".yml")){
		datas = readYaml file : yaml_file
		
	}else {
		datas = readYaml text : yaml_file
	}
	datas.each {
		println ( it.key + " = " + it.value )
	}
    def stages = [:]
    def jobs = [:]
    def steps = [:]
    def vmss = [:]
    def stagename = ""
    def jobname = ""
    stages = datas.stages
    println stages.stage
    stages.each {
        stagename = it.stage
        jobs = it.jobs
        jobs.each {
            jobname = it.job
            if ( it.vms != null && it.vms != "" )
            {
                vms = it.vms
                PrepareVMSAgent(stagename, jobname, it.vms)
            }
            steps = it.steps
            steps.each {
                println ("stage name is "+stagename)
                println ("job name is "+jobname)
                if ( it.task != "" && it.task != null) {
                    println ("this step is a task "+it.task)
                    ExcuteTask(stagename, jobname, vms, it)
                }
                if ( it.script != "" && it.script != null) {
                    println ("this step is a script "+it.script)
                    ExcuteScript(stagename, jobname, vms, it)
                }
            }
        }
        
    }

}
