%    ***************************************************************
%    *    Univeridade Federal do Esp�rito Santo - UFES             *                          
%    *    Course:  Master of Science                               *
%    *    Student: Mauro Sergio Mafra Moreira                      *
%    *    Email:   mauromafra@gmail.com                            *
%    *    Revision: 01                           Data 00/00/2019   *
%    ***************************************************************

% Description:


function rGetSensorOdomMsg(obj)

    obj.pOdom = rostopic(obj.pTxtTopic.Echo, obj.pTxtTopic.Odom);    
    
end
