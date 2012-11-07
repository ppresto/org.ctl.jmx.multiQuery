
package jmxquery;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;


//

public class jmxMonitor {
	List<Map<String,String>> jmxAttrList = new ArrayList <Map<String,String>>();
	
	public jmxMonitor(List<Map<String,String>> monitor){
		this.jmxAttrList = new ArrayList <Map<String,String>>(monitor);
	}

	boolean checkState(int RETURN_STATE) {
    	StringBuilder MsgDesc = new StringBuilder();
    	StringBuilder MsgCheckData = new StringBuilder();
    	StringBuilder MsgPerfData = new StringBuilder(" |");
    	boolean foundState = false;
    	for (Map<String, String> a: jmxAttrList){
	    		if (a.get("status").matches(Integer.toString(RETURN_STATE))){
	    			if (!foundState){
	    				MsgDesc.append(a.get("statusDesc"));
	    				foundState = true;
	    			}
	    		}
    	}
    	if (foundState){
	    	for (Map<String, String> a: jmxAttrList) {
	    		if (a.get("status").matches(Integer.toString(RETURN_STATE))) {
			    	for (Map.Entry<String, String> entry : a.entrySet()){
			    		if (!entry.getKey().equals("status") && !entry.getKey().equals("statusDesc") && !entry.getKey().equals("perfData")){
			    			MsgCheckData.append(" "+ entry.getKey() +"="+ entry.getValue());
			  			}
			  		}
	    		}
	    	}
	    	for (Map<String, String> a: jmxAttrList){
			    for (Map.Entry<String, String> entry : a.entrySet()){
		    		if (entry.getKey().equals("perfData")){
		    			MsgPerfData.append(" "+ entry.getValue());
		    		}
		    	}
	    	}
		    System.out.println("\n\n"+ MsgDesc.toString() + MsgCheckData.toString() + MsgPerfData.toString());
		    return true;
    	}    	
		return false;
    }
	
}