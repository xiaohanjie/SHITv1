import hudson.model.*;

pipeline {
    agent any
    environment {
        WORKSPACE_PATH = "${WORKSPACE}"
        SCRIPT_PATH = "${WORKSPACE}/script"
        ANSIBLE_PATH = "${WORKSPACE}/ansible"
        AGENTCONFIG_PATH = "${WORKSPACE}/conf"
        TEMP_PATH = "${WORKSPACE}/tmp"
        VMS_SCRIPT = "${WORKSPACE}/test.sh"
    }
    stages {
        stage('prepareEnv') {
            steps {
                withFileParameter('ymlfile') {
                    script {
                        dir("$ANSIBLE_PATH") {
                            git branch: "${branch}", url: "${url}"
                        }
                        read_yaml_file(ymlfile)
                    }
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
      sh(script: "/usr/bin/bash ${WORKSPACE}/$Cmd", returnStdout: true).trim()
    } else {
      sh "/usr/bin/bash ${WORKSPACE}/$Cmd"
    }
}

def PrepareVMSAgent(Stage, Job, VmsAgent) {
    def vms = [:] 
    def configtext = ""
    vms = VmsAgent
    VmsAgentCONFIGFile = Stage + "-" + Job + "-" + vms.vmsagentname + "-AGENTCONFIG"
    VmsAgentCONFIGFilePATH = AGENTCONFIG_PATH + "/" + VmsAgentCONFIGFile
    vms.each {
        configtext = configtext + it.key + "=" + it.value + "\n"
    }
    writeFile file: VmsAgentCONFIGFilePATH, text: configtext
    stage(Job + "prepareVMS" + vms.vmsagentname) {
        try {
            sh "/usr/bin/bash ${VMS_SCRIPT} ${VmsAgentCONFIGFile}"
        } 
        catch (exc) {
            println "prepareVMS ${vms.vmsagentname}: STAGE_FAILED_EXECPTION"
            currentBuild.result = 'FAILURE'
            throw exc
        }					
    }
}

def CleanupVMSAgent(Stage) {
    RunShellScript("cleanup.sh $Stage")
}

def ExcuteTask(Stage, Job, VmsAgent, Task) {
    def inputs = [:]
	def text = ""
	def vms = [:]
	vms = VmsAgent
    VmsAgentName = Stage + "-" + Job + "-" + vms.vmsagentname
	VmsAgentCONFIGFile = VmsAgentName + "-AGENTCONFIG"
    inputs = Task.inputs	
    if (Task.type ==~ "ansible")
    { 
        node {
            stage(Job + " " + Task.type ) {
                try {
                    def ansibledir = ANSIBLE_PATH + "/" + Task.task
                    inputs.each {
                        text = it.value + " " + text 
                        
                    }
                    sh "/usr/bin/bash ${ansibledir}/run.sh ${VmsAgentCONFIGFile} ${text}"
                } catch (exc) {
                    println exc
                }					
		    }
		}		
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
                    stage(Job + " " + "Script" ) {
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
                stage(Job + " " + "Script") {
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

def read_yaml_file(file) {
    def	yaml_file = readFile file
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
