/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of condit
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
global class ChatterAuditBatchLoader implements Database.Batchable<SObject>, Database.Stateful{
 
	private ChatterAuditBatchLoaderUtils utils;
	private Integer proccessedRecords;

	/**
	 * Batch Update
 	 */
	global ChatterAuditBatchLoader(){
        this.utils = new ChatterAuditBatchLoaderUtils() ;
        this.proccessedRecords = 0;
    }

    /**
	 * Batch Start Method
	 *
	 * @param ctx
	 * @return				String with query
 	 */
    global Iterable<sObject> start(Database.BatchableContext ctx){
    	String qStr = this.utils.getSelectQuery();    	
        return Database.query( qStr );
    } 

    /**
	 * Batch execute Method
	 *
	 * @param ctx
	 * @param data		List of Sobject
 	 */
    global void execute(Database.BatchableContext ctx, List<Sobject> data){
		this.proccessedRecords	= this.utils.loadChatterRecords(data);
    }
 
    /**
	 * Batch Finish Method
	 *
	 * @param ctx
 	 */
    global void finish(Database.BatchableContext ctx){

				AsyncApexJob a = [SELECT id, ApexClassId,
                       JobItemsProcessed, TotalJobItems,
                       NumberOfErrors, CreatedBy.Email
                       FROM AsyncApexJob  
                       WHERE id = :ctx.getJobId()]; 
				
				//Add limit to an agregate query because security scanner warnings
				Integer total = [Select count() from ArchivedFeedItem__c limit 49999]; 

		        String emailMsg   =  Label.ChatterAudit_BatchJobPreLoadEmailMessage;
		        String emailTitle =  Label.ChatterAudit_BatchJobEmailTitle;
		 		emailMsg= emailMsg.replaceAll('ChatterAuditBatchUpdate','ChatterAuditDataPreLoading');
		        emailMsg= emailMsg.replaceAll('totalJobItems',String.valueOf(a.totalJobItems));
		        emailMsg= emailMsg.replaceAll('jobitemsprocessed',String.valueOf(a.jobitemsprocessed));
		        emailMsg= emailMsg.replaceAll('numberOfErrors',String.valueOf(a.numberOfErrors));
		        emailMsg= emailMsg.replaceAll('proccessedRecords',String.valueOf(total));
			
		        ChatterAuditUtils.sendMail(a.createdBy.email, emailTitle,emailMsg);		
    }
}