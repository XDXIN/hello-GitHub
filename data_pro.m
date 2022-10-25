%数据预处理部分算法流程
% r1 weather file
% r2, irradiance file
% r3   solar Gen File
% r4,  WRF NE
% 
% Headers={0,1}  1表示带表头
% Res:           数据的时间分辨率
% DataCols       ：数据列数
% hem            ：1/东半球   0/西半球
% Ltm            ：位置时
% L              ：维度
% Lat            ：经度
% N              ：N点平均的个数
% GenIrrad       ：光照
% GenCapacity
% WeatherFileHourlyOrRes
% DataCumulativeOrNot
% RelativeHours
% 
% 
% 
% set(handles.b3,'String','Weather File Processing');
% set(handles.b4,'String','Minute to Minute Conversion');
if r1==1
    
    [ ProcessedData ] = SolarPVWeatherDataCleaner( Headers,Res,DataCols,hem,Ltm,L,Lat,N );
    
elseif r2==1
    PlantInfo_Parameters=getappdata(PlantInfo_GUI,'PlantInfo_Parameters');
    % Using external function to process Irradiance File
    [ ProcessedData,~,~ ] = SolarPVIrradianceDataCleaner( Headers,Res,DataCols,hem,Ltm,L,Lat,GenIrrad,PlantInfo_Parameters );
elseif r3==1
     PlantInfo_Parameters=getappdata(PlantInfo_GUI,'PlantInfo_Parameters');    

    % Using external function to process Generation File
    
   [ ProcessedData,~,~ ] = SolarPVGenerationDataCleaner( Headers,Res,DataCols,hem,Ltm,L,Lat,GenCapacity,GenIrrad, WeatherFileHourlyOrRes, DataCumulativeOrNot, PlantInfo_Parameters );    


elseif r4==1
    
    
    RelativeHours=get(handles.RelativeHours,'String');
    RelativeHours=str2double(RelativeHours); 
        
    % Using external function to process WRF NETCDF File
    
    [ ProcessedData ] = WrfUTC_To_LocalSolarTime( Headers,hem,Ltm,L,Lat,RelativeHours);
    
end

%%分辨率转化部分
%r5,r6,r7  表示各自部分
%Datacols:数据列数
%ResOriginal：数据初始分辨率
%resNew：新的分辨率
%AvgOrAdd:计算方式：1/表示取平均   0/表示求和
if (r5==1) % Minute to Minute
    % Using External Function to perform Conversion
    [ ProcessedData1 ] = minToMINDataCoverter( DataCols,ResOriginal,ResNew,AvgOrAdd );
    
elseif (r6==1) % Minute to Day
    [ ProcessedData1 ] = MINToDayDataCoverter( DataCols,Res,AvgOrAdd );
    
elseif(r7==1) % Day to Month
    % Using External Function to perform Conversion
    [ ProcessedData1 ] = DayToMonthDataCoverter( DataCols,AvgOrAdd );
end



%%SolarPVWeatherDataCleaner计算过程
[ ProcessedData ] = SolarPVWeatherDataCleaner( Headers,Res,DataCols,hem,Ltm,L,Lat,N  )


[~ ,~,DataFile]=xlsread(Fullpathname,1);
% 读取的数据为元胞类型，第一列为时间，2：end为所需分析数据
if Headers==1
    % Getting the Header Text
    Header1 = DataFile(1,2:(DataCols+1));
    % Changes for handling GMC Date-Time Stamp
    %获取数据的初始时间及结束时间
    DateTimeStampStartday=strread(DataFile{2,1},'%s','delimiter','T'); % The Delimiter is chnaged from ' ' to 'T'
    % Start day Information
    StartDate=strread(DateTimeStampStartday{1,1},'%f','delimiter','-'); % The Delimiter is chnaged from '/' to '-'
    
    StartYear=StartDate(1,1);
    
    StartMonth=StartDate(2,1);
    
    StartDay=StartDate(3,1);
    % End Day Information
    [rnum,colnum]=size(DataFile);

    DateTimeStampEndday=strread(DataFile{rnum,1},'%s','delimiter','T'); % The Delimiter is chnaged from ' ' to 'T'

    EndDate=strread(DateTimeStampEndday{1,1},'%f','delimiter','-'); % The Delimiter is chnaged from '/' to '-'

    EndYear=EndDate(1,1);

    EndMonth=EndDate(2,1);

    EndDay=EndDate(3,1);

elseif Headers==0
    %同上处理
end
% Computing Rows And Columns for the Processed Data File using Pre-defined Function
%RowsColsToComputeDataCleaning函数根据始终日期计算数据的行数和列数
[ Rows,Cols,TotDays ] = RowsColsToComputeDataCleaning( StartYear,StartMonth,StartDay,EndYear,EndMonth,EndDay,Res,DataCols,4 );

% Initializing Processed Data File to zeros

ProcessedData=NaN(Rows,Cols);

% Initializing Data Captur Matrix to Zeros

DataCapture=zeros(1,DataCols);

%% Putting Data into CORRECT ROWS & COLUMNS from Raw Data File to the Pre-Initialized Processed Data file

% Creating Date Time (Decimal Solar Time) Matrix for the given number of Days using Pre-Defined Function

[ DateTimeMatrix,~,TimeT ] = StartEndCalender( StartYear,StartMonth,StartDay,TotDays,Res,DataCols );

TimeT=TimeT'; % Converting Column Vector to Row Vector
len=length(TimeT); 

% Copying the DateTimeMatrix to the ProcessedData Matrix

ProcessedData=DateTimeMatrix;
[rrnum,ccnum]=size(ProcessedData);
len1=rrnum;
Up=1; % This variable will be updated whithin the following for loop to make UPDATEING FOR LOOP Dynamic to Compute FASTER

First=0; % Debugger

% Updating ProcessedData Data Columns in ProcessedData matrix for each row in Original Data File

for i=1:rnum
    
    First=First+1 % Debugger
    
       if Headers==1 % Use Index as 'i+1'
           
           % Providing a BREAK SITUATION when index 'i' goes out of bounds
           Breaker=i+1;
           
           if Breaker>rnum
               
               break;
               
           end
           
           % Reading Date Time Signature of Current Data Row
           
            DateTimeStamp=strread(DataFile{i+1,1},'%s','delimiter','T'); % The Delimiter is chnaged from ' ' to 'T'

            % Current Instant Date Information

            Date=strread(DateTimeStamp{1,1},'%f','delimiter','-'); % The Delimiter is chnaged from '/' to '-'

            Year=Date(1,1);

            Month=Date(2,1);

            Day=Date(3,1);
            
            % Current Instant Time Information
            
            Time=strread(DateTimeStamp{2,1},'%f','delimiter',':');

            Hour=Time(1,1);

            Min=Time(2,1);

            Sec=Time(3,1);

%             DayAmPm=strread(DateTimeStamp{3,1},'%s');
%            转化为十进制时间
            [ TimeDeci ] = HMToDeci( Hour,Min,Sec );
            
            % Reading Data from the Current Row of DataFile into DataCapture Vector
            %DataCapture=zeros(1,DataCols);   DataFile={5248,3},i=1
            for k=2:(DataCols+1)
                
                DataCapture(1,k-1)=DataFile{i+1,k};
                %%将负值调整为0
                if (DataCapture(1,k-1)<0) % [Modified]Converting NEGATIVE Values to ZEROS only for Variables other than Temperature Column
                            DataCapture(1,k-1)=0;       
                end
            end       
            % Finding Corrected Time value for Time Deci as per the Time Signature of ProcessedData Matrix
            for j=1:len

                diffrence(1,j)=abs(TimeDeci-TimeT(1,j));

            end

            [M,I]=min(diffrence);

            T=TimeT(1,I); % Corrected Time Value 
            
            % Computing CORRECT INDEX (Using: Day, Month, Year and T) of the ProcessesdData Matrix where the Current Data should be Stored
            
            for l=Up:len1
                
                if (Day==ProcessedData(l,1))&&(Month==ProcessedData(l,2))&&(Year==ProcessedData(l,3))&&(T==ProcessedData(l,4))
                    
                  break; 
                    
                end                
                
            end
            
            Up=Up+1; % Updating Loop Starting Point for Faster Computation
            
            % Storing Data from DataCapture Matrix to the ProcessedData Matrix at the Correct Location (Given by INDEX 'l')
            
            for m=1:DataCols
                
                ProcessedData(l,m+4)=DataCapture(1,m);                
                
            end
           
       elseif Headers==0 % Use Index as 'i'
           
           % Reading Date Time Signature of Current Data Row
           
            DateTimeStamp=strread(DataFile{i,1},'%s','delimiter','T'); % The Delimiter is chnaged from ' ' to 'T'

            % Current Instant Date Information

            Date=strread(DateTimeStamp{1,1},'%f','delimiter','-'); % The Delimiter is chnaged from '/' to '-'

            Year=StartDate(1,1);

            Month=StartDate(2,1);

            Day=StartDate(3,1);
            
            % Current Instant Time Information
            
            Time=strread(DateTimeStamp{2,1},'%f','delimiter',':');

            Hour=Time(1,1);

            Min=Time(2,1);

            Sec=Time(3,1);

%             DayAmPm=strread(DateTimeStamp{3,1},'%s');

            [ TimeDeci ] = HMToDeci( Hour,Min,Sec );

            
            % Reading Data from the Current Row of DataFile into DataCapture Vector
            for k=2:(DataCols+1)
                
                DataCapture(1,k-1)=DataFile{i+1,k};
                
                if DataCapture(1,k-1)<0 % Converting NEGATIVE Values to ZEROS
                    
                  DataCapture(1,k-1)=0;  
                    
                end
                
            end
        
            % Finding Corrected Time value for Time Deci as per the Time Signature of ProcessedData Matrix            
            for j=1:len

                diffrence(1,j)=abs(TimeDeci-TimeT(1,j));

            end

            [M,I]=min(diffrence);

            T=TimeT(1,I); % Corrected Time Value  
            
            % Computing CORRECT INDEX (Using: Day, Month, Year and T) of the ProcessesdData Matrix where the Current Data should be Stored
            
            for l=Up:len1
                
                if (Day==ProcessedData(l,1))&&(Month==ProcessedData(l,2))&&(Year==ProcessedData(l,3))&&(T==ProcessedData(l,4))
                    
                  break; 
                    
                end
                
            end
            
            Up=Up+1; % Updating Loop Starting Point for Faster Computation           
           
            % Storing Data from DataCapture Matrix to the ProcessedData Matrix at the Correct Location (Given by INDEX 'l')
            
            for m=1:DataCols
                
                ProcessedData(l,m+4)=DataCapture(1,m);
                
            end
            
           
       end
    
end

%% N Point Average Method for Filling missing Data in TEMPERATURE, WIND, RELATIVE HUMIDITY

RaN=zeros(N,DataCols); % Initializing the Running Value Storage used in NaN Value Filling 

NPointAverageN=sum(RaN)/N; % Calculating the Running Average

Second=0; % Debugger

% FOR LOOP for Point-Wise Filling of NaN and Zero Values (Top to Bottom)

for i=1:Rows
    
    Second=Second+1 % Debugger
    
    RaCounter=rem(i,N); % For using Running Value Storage Vector to cyclically update its N Values with the next value
    
    if RaCounter==0
        
        RaCounter=N;
        
    end
    
    % FOR LOOP for Each Data Column
    %N点平均
    for k=1:DataCols
        
        if (isnan(ProcessedData(i,k+4)))||(ProcessedData(i,k+4)==0)
            
            NPointAverageN=sum(RaN(:,k))/N; % Calculating the Running Average
            
            ProcessedData(i,k+4)=NPointAverageN; % Updating NaN Value with Running Average Value
        
            RaN(RaCounter,k)=ProcessedData(i,k+4);
            
        else
            
            RaN(RaCounter,k)=ProcessedData(i,k+4);
            
        end
        
   
    end
    
    
    
end

% FOR LOOP for Point-Wise Filling of NaN and Zero Values (Bottom to Top)

Third=0; % Debugger

for i=Rows:-1:1
    
    Third=Third+1 % Debugger
    
    RaCounter=rem(i,N); % For using Running Value Storage Vector to cyclically update its N Values with the next value
    
    if RaCounter==0
        
        RaCounter=N;
        
    end
    
    % FOR LOOP for Each Data Column
    
    for k=1:DataCols
        
        if (isnan(ProcessedData(i,k+4)))
            
            NPointAverageN=sum(RaN(:,k))/N; % Calculating the Running Average
            
            ProcessedData(i,k+4)=NPointAverageN; % Updating NaN Value with Running Average Value
        
            RaN(RaCounter,k)=ProcessedData(i,k+4);
            
        else
            
            RaN(RaCounter,k)=ProcessedData(i,k+4);
            
        end   
    end
end




%%RowsColsToComputeDataCleaning
%%具体计算过程如下
[ Rows,Cols,TotDays ]=RowsColsToComputeDataCleaning( StartYear,StartMonth,StartDay,EndYear,EndMonth,EndDay,Res,DataCols,DateTimeCols )
% Computing the Total number of Different Years in the Data
NumOfYears=EndYear-StartYear+1;%%年数

% Computing the Different Year Signature Values
for i=1:NumOfYears
    
    Year(1,i)=StartYear+i-1;
    
end
% Finding the Leap and Non-Leap Year
LeapYear= LeapYearFinder( Year ); 

% Initializing Day Counters
a=0;
b=0;
c=zeros(1,NumOfYears);

% Computing Number of days in the given Data Set
for j=1:NumOfYears
    
    if j==1 % Days for Start Year
        
        if NumOfYears==1
            
            [ StartDay1, EndDay1 ] = DaysToCompute( LeapYear(1,j),StartDay,StartMonth,EndDay,EndMonth );
            
            a=EndDay1-StartDay1+1; %Total Numbe of Days
            
        else
            
            [ StartDay1, EndDay1 ] = DaysToCompute( LeapYear(1,j),StartDay,StartMonth,31,12 );
            
            a=EndDay1-StartDay1+1; %Total Numbe of Days
        
        end
        
    elseif j==NumOfYears % Days for End Year
        
       [ StartDay1, EndDay1 ] = DaysToCompute( LeapYear(1,j),1,1,EndDay,EndMonth ) ;
       
       b=EndDay1-StartDay1+1; %Total Numbe of Days
        
    else % Days for all other Years  
        
        [ StartDay1, EndDay1 ] = DaysToCompute( LeapYear(1,j),1,1,31,12 );
        
        c(1,j)=EndDay1-StartDay1+1; %Total Numbe of Days
        
    end
    
end

% Total Number of Days in the Data Set
TotDays=a+b;

for k=1:NumOfYears
    
TotDays=TotDays+c(1,k);

end

% Data Points in ONE DAY (Resolution has to be in Minutes)
DataPoints=24*(60/Res);

% Total Data Points in the Given Data Set i.e the Total Number of Rows
Rows=TotDays*DataPoints;

% Total Number of Collumns in the Data Set
Cols=DataCols+DateTimeCols;





%%%%%%%
%% minToMINDataCoverter   分钟到分钟的转化
[ ProcessedData1 ] = minToMINDataCoverter( DataCols,ResOriginal,ResNew,AvgOrAdd, Headers )
%
%只读入double类型数据列，不读入时间列
[ProcessedData]=xlsread(Fullpathname,1);

%% Computing Size of ProcessedData Matrix

[Row,Col]=size(ProcessedData);

RowNew=Row*(ResOriginal/ResNew); % [Embedded Formula] Computing Number of Rows for the PRocessedData1 Matrix

RowNew=ceil(RowNew);

% Initializing The New ProcessedData Matrix

ProcessedData1=zeros(RowNew,(4+DataCols));

% Computing Number off ROWS to be AVERAGED or ADDED

NumRows=ResNew/ResOriginal;

% [Modification] Recoding for Fractional NumRows Problem

NumRows_Frac = rem(ResNew, ResOriginal); % If NumRows_Frac==0 , There is no Fractional NumRows Problem (Use Earlier Algorithm) ; NumRows_Frac~=0 , There is Fractional NumRows Problem (Use New Algorithm)

if (Headers==1)
    
    % Getting Headers
    
    [~ ,~,DataFile]=xlsread(Fullpathname,1);
    
    % Getting the Header Text
    
    Header1 = DataFile(1,5:(DataCols+4));    
    
    % Clearing the not needed DataFile Variable
    
    clearvars DataFile
    
    Header = {'Day', 'Month', 'Year', 'Time'};
    
    % Concatenating Headers derived frome the Original File
    
    Header = [Header, Header1];    
    
elseif (Headers==0)
    
    Header = {'Day', 'Month', 'Year', 'Time'};
    
end

if (NumRows_Frac == 0) % Use Earlier Algorithm

    % Initializing Index for ProcessedData1 Matrix

    Index1=1;

    %% FOR LOOP for Averging and Adding to get Desired ResNew according to AvgOrAdd
    % FOR LOOP for each ROW of ProcessedData Skipping by NumRows
    for i=2:NumRows:Row
        % Correcting for the 0 Hour field on the First Row of the ProcessedData Matrix
        ProcessedData1(1,:)=ProcessedData(1,:); % Copying Correct DateTime Stamp

        % Incrementing Index1 for placing Data in Correct Rows of ProcessedData1 Matrix

        Index1 =Index1+1;

        % FOR LOOP for each DataCol

        for k=1:DataCols

            Indicator=AvgOrAdd(1,k); % For indication Values Should be Averaged or Added

            Add=0; % Initializing Add Variable to Zero

            Avg=zeros(1,NumRows); % Initializing Avg Vector to Zeros

            % FOR LOOP for Averaging & Adding as Per RES Values

            for j=1:NumRows

                RowIndex=i+(j-1); % Computing RowIndex

                if Indicator==1 % ADDITION

                    Add=Add+ProcessedData(RowIndex,(k+4));

                elseif Indicator==0 % AVERAGE

                    Avg(1,j)=ProcessedData(RowIndex,(k+4));

                end

            end        

            ProcessedData1(Index1,1:4)=ProcessedData(RowIndex,1:4); % Copying Correct DateTime Stamp

            if Indicator==1 % ADDITION

                 ProcessedData1(Index1,(k+4))=Add; % Copying Correct Data Value

            elseif Indicator==0 % AVERAGE

                 ProcessedData1(Index1,(k+4))=sum(Avg)/NumRows; % Copying Correct Data Value

            end

        end


    end
    
elseif (NumRows_Frac ~= 0) % [Modification] Use New Algorithm
    
    % Getting StartYear,StartMonth,StartDay,EndYear,EndMonth,EndDay from the Input File
    
    StartYear = ProcessedData(1,3);   
    StartMonth = ProcessedData(1,2);
    StartDay = ProcessedData(1,1);
    
    EndYear = ProcessedData(Row,3);
    EndMonth = ProcessedData(Row,2);
    EndDay = ProcessedData(Row,1);
    
    % Computing Rows And Columns for the Processed Data File using Pre-defined Function

    [ Rows1,Cols1,TotDays ] = RowsColsToComputeDataCleaning( StartYear,StartMonth,StartDay,EndYear,EndMonth,EndDay,ResNew,DataCols,4 );
    
    % Initializing Processed Data File to zeros

    ProcessedData1=zeros(Rows1,Cols1);
    
    % Creating Date Time (Decimal Time) Matrix for the given number of Days using Pre-Defined Function

    [ DateTimeMatrix,~,TimeT] = StartEndCalender( StartYear,StartMonth,StartDay,TotDays,ResNew,DataCols );
    
    % Filling the ProcessedData1 Matrix with Correct Time-Stamps
    
    ProcessedData1(:,1:4)=DateTimeMatrix(:,1:4);
    
    %% FOR LOOP for Averging and Adding to get Desired ResNew according to AvgOrAdd
    
    Index1=0; % Initializing The Row Counter for the New ProcessedData1 Matrix

    % FOR LOOP for each ROW of ProcessedData Skipping by NumRows      
    
    for i=1:NumRows:Row
        
        % Incrementing Index1
        
        Index1 = Index1+1;
        
        % Storing Previous Values of i
        
        RowNumVector(1,Index1)=i;    
        
        % Getting Current NumRow
        
        NumRow = i;
        
        
        % Correcting for the 0 Hour field on the First Row of the ProcessedData Matrix
        
        if (i==1) % The First Row
            
            ProcessedData1(1,:)=ProcessedData(1,:); % Copying the First Row as it is 
            
            continue; % Advance to Next Iteration
            
        end
        
        % Getting the Previous Row Num Value
        
        Previous_RowNum = RowNumVector(1,(Index1-1));
        
        % Finding whether the Previous_RowNum is Integer or Fractional

        IntFrac_Indicator2 = rem(Previous_RowNum,1); % Can be used for Additio Weight
        
        % Computing Num Row Previous based on the Previous_RowNum Value
        
        if (IntFrac_Indicator2==0) % Previous_NumRow is Integer
            
            NumRow_Previous = Previous_RowNum+1;            
            
            StartVal_Multiplier = 1;
            
        elseif (IntFrac_Indicator2~=0) % Previou_NumRow is Fractional
            
            NumRow_Previous = ceil(Previous_RowNum);
            
            StartVal_Multiplier = 1-IntFrac_Indicator2;
            
        end
        
        % Finding whether the current Num Row is Integer or Fractional
        
        IntFrac_Indicator1 = rem(i,1); % Can be used for Addition Weight
        
        % Computing Next Num Row based on the IntFrac_Indicator1
        
        if (IntFrac_Indicator1==0) % Current Num Row is Integer
            
            NumRow_Next = NumRow;
            
            EndVal_Multiplier = 1;
            
        elseif (IntFrac_Indicator1~=0) % Current Num Row is Fractional
            
            NumRow_Next = ceil(NumRow);
            
            EndVal_Multiplier = IntFrac_Indicator1;
            
        end
        
        % Getting the Actual Indices of the Original Data Set
        
        Actual_Indices = [NumRow_Previous:NumRow_Next];
        
        % FOR LOOP for each DataCol
        
        for k=1:DataCols

            Indicator=AvgOrAdd(1,k); % For indication Values Should be Averaged or Added
            
            % Collecting the Desired Values from the Current Columns from the Original Data Set
            
            Actual_Values=ProcessedData(Actual_Indices,(k+4));
            
            % Using the Indicator for Either Averaging or Addition of the Values
            
            if (Indicator==1)  % Perform Addition on the Desired Values
                
                % Computing Weighted Sum
                
                Actual_Values(1,1) = StartVal_Multiplier*Actual_Values(1,1);  % Correcting Addition Biases due to Fractional NumRows
                
                Actual_Values(end,1) = EndVal_Multiplier*Actual_Values(end,1); % Correcting Addition Biases due to Fractional NumRows
                
                Addition_Value = sum(Actual_Values);                
                
                % Putting the Addition_Value in the Correect Cell of the ProcessedData1 matrix
                
                ProcessedData1(Index1,(k+4)) = Addition_Value;
                
            elseif (Indicator==0) % Perform Averaging on the Desired Values
                
                % Computing Average
                
                Averaged_Value = sum(Actual_Values)/length(Actual_Values);
                
                % Putting the Averaged_Value in the Correect Cell of the ProcessedData1 matrix
                
                ProcessedData1(Index1,(k+4)) = Averaged_Value;               
                
            end
            
            
        end    
       
               
     end
    
end


