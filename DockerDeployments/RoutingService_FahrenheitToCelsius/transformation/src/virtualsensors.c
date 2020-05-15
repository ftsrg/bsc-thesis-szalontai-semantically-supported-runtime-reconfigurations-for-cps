/* $Id$

 (c) Copyright, Real-Time Innovations, All rights reserved.       
                                                                          
 Permission to modify and use for internal purposes granted.      
 This software is provided "as is", without warranty, express or implied. 

An example of Routing Service transformation.
=========================================================================*/

#include "ndds/ndds_c.h"
#include "routingservice/routingservice_transformation.h"

#ifdef RTI_WIN32
#define DllExport __declspec( dllexport )
#else
#define DllExport
#endif

/* =========================================================================
   Data structures                                                         
   ========================================================================= */

/* @brief Transformation plugin
 *
 * Must be a RTI_RoutingServiceTransformationPlugin structure
 * containing the pointers to the API functions 
 */
struct VirtualSensorTransformationPlugin {
    struct RTI_RoutingServiceTransformationPlugin _base;
};

/* @brief Transformation object
 *
 * Represents a <transformation> in a <route>
 *
 * Contains the configuration passed with <property> and
 * a reference to the shape type passed by routing service.
 *
 */
struct VirtualSensorTransformation {

    /* @brief A reference to the plugin. Not used in the example
     */
    struct VirtualSensorTransformationPlugin * _plugin;

    const struct DDS_TypeCode * shapeType;

    char * unit;
    DDS_Double value;
    
};

/* =========================================================================
   Private functions                                                         
   ========================================================================= */

/* 
 * @brief Checks if the type info is a ShapeType type code
 */
int VirtualSensorTransformation_checkTypeCompatibility(
    const struct RTI_RoutingServiceTypeInfo * type)
{
    DDS_ExceptionCode_t ex;
    const char * name;
    struct DDS_TypeCode * tc = NULL;

    if(type->type_representation_kind != 
       RTI_ROUTING_SERVICE_TYPE_REPRESENTATION_DYNAMIC_TYPE) {
        return 0;
    }

    tc = (struct DDS_TypeCode *) type->type_representation;

    name = DDS_TypeCode_name(tc, &ex);

    if(ex != DDS_NO_EXCEPTION_CODE) {
	return 0;
    }

    /* We just compare the type code name */
    if(strcmp(name, "TemperatureSensor") != 0) {
	return 0;
    }

    return 1;
       
}

/* 
 * @brief Creates a dynamic data sample that is a copy of the input
 *        but changing the fixed values that the transformation tells
 */
struct DDS_DynamicData * VirtualSensorTransformationPlugin_createOutputSample(
        struct VirtualSensorTransformation * self,
        const struct DDS_DynamicData * input) {

    DDS_ReturnCode_t retCode;
    struct DDS_DynamicData * output = NULL;

    struct DDS_DynamicDataProperty_t dynamicDataProps = 
        DDS_DynamicDataProperty_t_INITIALIZER;

    output = DDS_DynamicData_new(self->shapeType, &dynamicDataProps);
    if(output == NULL) {
        return NULL;
    }

    retCode = DDS_DynamicData_copy(output, input);
    if(retCode != DDS_RETCODE_OK){
        DDS_DynamicData_delete(output);
	return NULL;
    }

    DDS_Double doubleValue;

    retCode = DDS_DynamicData_get_double(
        input, &doubleValue, "value", DDS_DYNAMIC_DATA_MEMBER_ID_UNSPECIFIED);
    if (retCode != DDS_RETCODE_OK) {
        DDS_DynamicData_delete(output);
        return NULL;
    }


    char* inputunit =NULL;
    DDS_UnsignedLong ulongvalue = 0;

    retCode = DDS_DynamicData_get_string(
        input, &inputunit,&ulongvalue, "unit",DDS_DYNAMIC_DATA_MEMBER_ID_UNSPECIFIED);
    if (retCode != DDS_RETCODE_OK) {
        DDS_DynamicData_delete(output);
        return NULL;
    }

    if (strcmp(inputunit, "cpsds:Unit_Fahrenheit") != 0) {
        DDS_DynamicData_delete(output);
        return NULL;
    }


    retCode = DDS_DynamicData_set_string(
        output, "unit", DDS_DYNAMIC_DATA_MEMBER_ID_UNSPECIFIED,"cpsds:Unit_Celsius");
    if (retCode != DDS_RETCODE_OK) {
        DDS_DynamicData_delete(output);
        return NULL;
    }

    DDS_Double FahrenheitToCelsius = (double) (doubleValue- 32)/1.8;

    if(self->value == -255){
	retCode = DDS_DynamicData_set_double(
        output, "value", DDS_DYNAMIC_DATA_MEMBER_ID_UNSPECIFIED, FahrenheitToCelsius);
	if(retCode != DDS_RETCODE_OK) {
            DDS_DynamicData_delete(output);
            return NULL;
	}
    }



    return output;
}

/* =========================================================================
   API implementation
   ========================================================================= */

/*
 * @brief  This function creates a transformation object
 *
 * This function is called by Routing Service when the transformation
 * is ready to be created and the types are available.
 *   
 * Routing Service will use the returned object to call
 * the transform function.
 *
 * @param transformationPlugin The plugin that will create
 *        this transformation
 * @param inputTypeInfo Information about the type of the
 *        data this transformation will receive to transform
 * @param outputTypeInfo Information about the type of the
 *        data this transformation will have to create
 * @param properties The configuration of this transformation, the
 *        string key-value pairs in the <transformation>/<property> 
 * @param env Routing Service environment. It can be used for
 *        error logging
 *
 * @return The user transformation object that will receive
 *         the transform calls
 */
RTI_RoutingServiceTransformation
VirtualSensorTransformationPlugin_create_transformation(
    struct RTI_RoutingServiceTransformationPlugin * transformationPlugin,
    const struct RTI_RoutingServiceTypeInfo * inputTypeInfo,
    const struct RTI_RoutingServiceTypeInfo * outputTypeInfo,
    const struct RTI_RoutingServiceProperties * properties,
    RTI_RoutingServiceEnvironment * env) {

    struct VirtualSensorTransformation * t = NULL;
    int i;

    /* 
     * Check that the input and output type are ShapeType 
     */

    if(!VirtualSensorTransformation_checkTypeCompatibility(inputTypeInfo)){
        RTI_RoutingServiceEnvironment_set_error(
            env, "Input type incompatible");
        return NULL;
    }

    if(!VirtualSensorTransformation_checkTypeCompatibility(outputTypeInfo)){
        RTI_RoutingServiceEnvironment_set_error(
            env, "Output type incompatible");
        return NULL;
    }

    /*
     * Create the transformation object
     */

    t = (struct VirtualSensorTransformation *)
        malloc(sizeof(struct VirtualSensorTransformation));

    if(t == NULL) {
        RTI_RoutingServiceEnvironment_set_error(
            env, "Memory allocation error");
        return NULL;
    }

    t->_plugin = (struct VirtualSensorTransformationPlugin *) transformationPlugin;

    /* We keep a reference to the type to create samples afterwards */
    t->shapeType = (struct DDS_TypeCode *) outputTypeInfo->type_representation;

    /*
     * Get the configuration properties
     */
    char c[256] = "";
    t->unit = c;
    double value = -255;
    t->value = value;



    for(i = 0; i<properties->count; i++) {



        if(!strcmp(properties->properties[i].name, "unit")) {
            t->unit = (char *) properties->properties[i].value;

        }
        else if (!strcmp(properties->properties[i].name, "value")) {
            
        }
    }

    return t;
}

/*
 * @brief This function deletes a transformation object
 *
 *
 */
void VirtualSensorTransformationPlugin_delete_transformation(
    struct RTI_RoutingServiceTransformationPlugin * transformationPlugin,
    RTI_RoutingServiceTransformation transformationObject,
    RTI_RoutingServiceEnvironment * env) {

    free(transformationObject);
}



/*
 * @brief Returns the array of samples created by transform
 *
 */
void VirtualSensorTransformation_return_loan(
     RTI_RoutingServiceTransformation transformationObject,
     RTI_RoutingServiceSample * sampleLst,
     RTI_RoutingServiceSampleInfo * infoLst,
     int count,
     RTI_RoutingServiceEnvironment * env) {

    int i;

    for(i = 0; i < count; i++) {
        DDS_DynamicData_delete((struct DDS_DynamicData *) sampleLst[i]);
    }

    free(sampleLst);
    
}

/*
 * @brief Creates shapes with the fixed x, y and shapesize values
 *
 * The transformation creates shapes based on the input samples
 * and changes their values of the fields x, y and/or shapesize
 * with the values configured by the user
 *
 */
void VirtualSensorTransformation_transform(
         RTI_RoutingServiceTransformation transformation,
         RTI_RoutingServiceSample ** outSampleLst,
         RTI_RoutingServiceSampleInfo ** outInfoLst,
         int * outCount,
         RTI_RoutingServiceSample * inSampleLst,
         RTI_RoutingServiceSampleInfo * inInfoLst,
         int inCount,
         RTI_RoutingServiceEnvironment * env) {

    int i;
    struct VirtualSensorTransformation * self = (struct VirtualSensorTransformation *) transformation;

    /* 
     * The transformation is on a sample-by-sample basis; 
     * no filtering or extra samples created 
     */
    *outCount = inCount;
    /* 
     * We don't transform the sample info 
     */
    *outInfoLst = inInfoLst;

    *outSampleLst = malloc(*outCount * sizeof(struct DDS_DynamicData *));
    if(*outSampleLst == NULL) {
        RTI_RoutingServiceEnvironment_set_error(
            env, "Error allocating output array");
        return;
    }

    for(i = 0; i < *outCount; i++) {

        (*outSampleLst)[i] = 
            VirtualSensorTransformationPlugin_createOutputSample(self, inSampleLst[i]);

        if((*outSampleLst)[i] == NULL) {
            RTI_RoutingServiceEnvironment_set_error(
                env, "Error creating output sample");
            VirtualSensorTransformation_return_loan(self, *outSampleLst, NULL, i, env);
            return;
        }
        
    }
    
}


/*
 * @brief Update the transformation configuration
 *
 * Allows changing the x, y and shapesize values when routing service
 * calls update after a remote command is processed
 *
 */
void VirtualSensorTransformationPlugin_update(
    RTI_RoutingServiceTransformation transformation,
    const struct RTI_RoutingServiceProperties * properties,
    RTI_RoutingServiceEnvironment * env) {

    int i;
    struct VirtualSensorTransformation * self = 
        (struct VirtualSensorTransformation *) transformation;

    for(i = 0; i<properties->count; i++) {
        for (i = 0; i < properties->count; i++) {
            if (!strcmp(properties->properties[i].name, "unit")) {
                self->unit = (char*)properties->properties[i].value;
            }
            else if (!strcmp(properties->properties[i].name, "value")) {

               self->value = atof((const char*)properties->properties[i].value);
            }
        
        }
    }
}



/*
 * @brief Deletes the plugin
 */
void VirtualSensorTransformationPlugin_delete(
    struct RTI_RoutingServiceTransformationPlugin * transformationPlugin,
    RTI_RoutingServiceEnvironment * env) {

    free(transformationPlugin);

}

/*
 * @brief Entry point to the plugin, creates the plugin instance
 *
 * It has to assign the pointers to the API functions
 *
 */
DllExport
struct RTI_RoutingServiceTransformationPlugin * 
VirtualSensorTransformationPlugin_create(
    const struct RTI_RoutingServiceProperties * properties,
    RTI_RoutingServiceEnvironment * env) {

    struct VirtualSensorTransformationPlugin * self = NULL;

    self = (struct VirtualSensorTransformationPlugin *)
        calloc(1, sizeof(struct VirtualSensorTransformationPlugin));

    if (self == NULL) {
        RTI_RoutingServiceEnvironment_set_error(
            env, "Memory allocation error");
        return NULL;
    }

    /*
     * This call is mandatory
     */
    RTI_RoutingServiceTransformationPlugin_initialize(&self->_base);

    self->_base.plugin_version.major = 1;
    self->_base.plugin_version.minor = 0;
    self->_base.plugin_version.release = 0;
    self->_base.plugin_version.release = 0;

    self->_base.transformation_plugin_delete = 
        VirtualSensorTransformationPlugin_delete;
    self->_base.transformation_plugin_create_transformation = 
        VirtualSensorTransformationPlugin_create_transformation;
    self->_base.transformation_plugin_delete_transformation =
        VirtualSensorTransformationPlugin_delete_transformation;
    self->_base.transformation_transform =
        VirtualSensorTransformation_transform;
    self->_base.transformation_return_loan =
        VirtualSensorTransformation_return_loan;

    return (struct RTI_RoutingServiceTransformationPlugin *) self;

}

