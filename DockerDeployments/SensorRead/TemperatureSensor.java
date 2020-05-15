

/*
WARNING: THIS FILE IS AUTO-GENERATED. DO NOT MODIFY.

This file was generated from .idl using "rtiddsgen".
The rtiddsgen tool is part of the RTI Connext distribution.
For more information, type 'rtiddsgen -help' at a command shell
or consult the RTI Connext manual.
*/

import com.rti.dds.infrastructure.*;
import com.rti.dds.infrastructure.Copyable;
import java.io.Serializable;
import com.rti.dds.cdr.CdrHelper;

public class TemperatureSensor   implements Copyable, Serializable{

    public String sensorID= (String)""; /* maximum length = (255) */
    public String location= (String)""; /* maximum length = (255) */
    public String unit= (String)""; /* maximum length = (255) */
    public double value = (double)0;
    public String readtime= (String)""; /* maximum length = (255) */

    public TemperatureSensor() {

    }
    public TemperatureSensor (TemperatureSensor other) {

        this();
        copy_from(other);
    }

    public static Object create() {

        TemperatureSensor self;
        self = new  TemperatureSensor();
        self.clear();
        return self;

    }

    public void clear() {

        sensorID = (String)"";
        location = (String)"";
        unit = (String)"";
        value = (double)0;
        readtime = (String)"";
    }

    public boolean equals(Object o) {

        if (o == null) {
            return false;
        }        

        if(getClass() != o.getClass()) {
            return false;
        }

        TemperatureSensor otherObj = (TemperatureSensor)o;

        if(!sensorID.equals(otherObj.sensorID)) {
            return false;
        }
        if(!location.equals(otherObj.location)) {
            return false;
        }
        if(!unit.equals(otherObj.unit)) {
            return false;
        }
        if(value != otherObj.value) {
            return false;
        }
        if(!readtime.equals(otherObj.readtime)) {
            return false;
        }

        return true;
    }

    public int hashCode() {
        int __result = 0;
        __result += sensorID.hashCode(); 
        __result += location.hashCode(); 
        __result += unit.hashCode(); 
        __result += (int)value;
        __result += readtime.hashCode(); 
        return __result;
    }

    /**
    * This is the implementation of the <code>Copyable</code> interface.
    * This method will perform a deep copy of <code>src</code>
    * This method could be placed into <code>TemperatureSensorTypeSupport</code>
    * rather than here by using the <code>-noCopyable</code> option
    * to rtiddsgen.
    * 
    * @param src The Object which contains the data to be copied.
    * @return Returns <code>this</code>.
    * @exception NullPointerException If <code>src</code> is null.
    * @exception ClassCastException If <code>src</code> is not the 
    * same type as <code>this</code>.
    * @see com.rti.dds.infrastructure.Copyable#copy_from(java.lang.Object)
    */
    public Object copy_from(Object src) {

        TemperatureSensor typedSrc = (TemperatureSensor) src;
        TemperatureSensor typedDst = this;

        typedDst.sensorID = typedSrc.sensorID;
        typedDst.location = typedSrc.location;
        typedDst.unit = typedSrc.unit;
        typedDst.value = typedSrc.value;
        typedDst.readtime = typedSrc.readtime;

        return this;
    }

    public String toString(){
        return toString("", 0);
    }

    public String toString(String desc, int indent) {
        StringBuffer strBuffer = new StringBuffer();        

        if (desc != null) {
            CdrHelper.printIndent(strBuffer, indent);
            strBuffer.append(desc).append(":\n");
        }

        CdrHelper.printIndent(strBuffer, indent+1);        
        strBuffer.append("sensorID: ").append(sensorID).append("\n");  
        CdrHelper.printIndent(strBuffer, indent+1);        
        strBuffer.append("location: ").append(location).append("\n");  
        CdrHelper.printIndent(strBuffer, indent+1);        
        strBuffer.append("unit: ").append(unit).append("\n");  
        CdrHelper.printIndent(strBuffer, indent+1);        
        strBuffer.append("value: ").append(value).append("\n");  
        CdrHelper.printIndent(strBuffer, indent+1);        
        strBuffer.append("readtime: ").append(readtime).append("\n");  

        return strBuffer.toString();
    }

}
