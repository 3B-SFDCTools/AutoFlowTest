@isTest
public with sharing class GenericFlowTest {
    private map<string,map<string,object>> inputVariablesByFlowName;
    private map<string,map<string,object>> outputVariablesByFlowName;
    private flow.Interview testedFlow;
    public map<string,boolean> flowTestResult;
    private list<string> flowNames;

    public GenericFlowTest() {
        this.flowTestResult = new map<string,boolean>();
        this.inputVariablesByFlowName = new map<string,map<string,object>>();
        this.outputVariablesByFlowName = new map<string,map<string,object>>();
        setFlowVariables();
    }

    //set the variable maps by iterating the Custom Metadata Records
    private void setFlowVariables(){
        for( flowTest__mdt tflow:[SELECT label,developername,(
                    SELECT Key__c,Type__c,value__c from Flowvariables__r order by Type__c)
                    FROM FlowTest__mdt
        ]){
            string flowName = tflow.label;
            inputVariablesByFlowName.put(flowName,new map<string,object>());
            outputVariablesByFlowName.put(flowName,new map<string,object>());
            for(FlowVariable__mdt flowvar:tflow.FlowVariables__r){
                if(flowVar.type__c == 'Input Variable'){
                    AddToInputVariables(flowName, flowVar);
                }
                else if(flowVar.type__c == 'Output Variable'){
                    addToOutputVariables(flowname, flowVar);
                }
            }
        }
    }
    public void testFlows(){
        //iterate the flows and test
        for(string eachFlow: flowNames){
            testFlow(eachFlow);
        }
    }

    private void testFlow(string flowName){
        setFlowVariables();
        startFlow(flowName);
        testFlowOutput(flowName);
    }

    //method to add the variable to the map
    private void AddToInputVariables(string flowName,FlowVariable__mdt flowVar){
        map<string,object> variableMap = inputVariablesByFlowName.get(flowname);
        variableMap.put(flowVar.key__c,flowVar.value__c);
    }
    private void addToOutputVariables(string flowname,FlowVariable__mdt flowVar){
        map<string,object> variableMap = outputVariablesByFlowName.get(flowname);
        variableMap.put(flowVar.key__c,flowVar.value__c);
    }

    //start a flow to test
    private void startFlow(string flowName){
        this.testedFlow = Flow.interview.createInterview(flowName, inputVariablesByFlowName.get(flowName));
        testedFlow.start();
    }

    //test an individual flows output variables
    private boolean testFlowOutput(string flowName){

        map<string,object> flowVariables = new map<string,object>();
    
        for (string key:outputVariablesByFlowName.get(flowName).keySet()){
            flowVariables.put(key, testedFlow.getVariableValue(key));
        }

        return AssertOutputVariables(flowName, flowVariables);
    }

    //test the variables from a flow
    private boolean assertOutputVariables(string flowName, map<string,object> flowOutput){
        map<string,object> flowVariables = outputVariablesByFlowName.get(flowName);
        for(string varKey: flowVariables.keySet()){
            try{
                system.assertEquals(flowVariables.get(varKey),flowOutput.get(varKey), 'Values for ' + varKey + ' did not match for flow: ' + flowName + ' -- ' + flowOutput.get(varKey));
            }
            catch (exception e){
                flowTestResult.put(flowName,false);
                return false;
            }
        }
        flowTestResult.put(flowName,true);
        return true;
    }


    @isTest 
    static void FlowTestMethod(){
        GenericFlowTest tester = new GenericFlowTest();
        tester.testFlows();
    }
}
