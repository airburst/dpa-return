SELECT ldv.id loan_id,
pv.prefixedpersonid person_id,
pv.dateofbirth date_of_birth,
la.loan_activation_date,
dpa_requests.loan_abandoned_date,
(CASE WHEN la.loan_activation_date IS NOT NULL AND pv.dateofbirth IS NOT NULL AND ((la.loan_activation_date - pv.dateofbirth ) / 365.25 ) >=18 AND ((la.loan_activation_date - pv.dateofbirth ) / 365.25 ) < 65  THEN '18-64'
      WHEN la.loan_activation_date IS NOT NULL AND pv.dateofbirth IS NOT NULL AND ((la.loan_activation_date - pv.dateofbirth ) / 365.25 ) > 65 THEN '65+'
      WHEN la.loan_activation_date IS NULL AND pv.dateofbirth IS NOT NULL AND ((dpa_requests.loan_abandoned_date - pv.dateofbirth ) / 365.25 ) >=18 AND ((dpa_requests.loan_abandoned_date - pv.dateofbirth ) / 365.25 ) < 65  THEN '18-64'
      WHEN la.loan_activation_date IS NULL AND pv.dateofbirth IS NOT NULL AND ((dpa_requests.loan_abandoned_date - pv.dateofbirth ) / 365.25 ) > 65  THEN '65+'
END) age_group,
ldv.typeofloan,
(CASE WHEN CAST(total_value_outstanding.DPA001Row1 AS VARCHAR(3)) = 'Yes' THEN 'Yes' ELSE 'No' END) DPA_Open_At_Census_End_Date,
(CASE WHEN total_value_outstanding.Value_Outstanding_At_End_Date IS NULL THEN 0.00 ELSE total_value_outstanding.Value_Outstanding_At_End_Date END) Value_Outstanding_At_End_Date,
(CASE WHEN CAST (New_Dpa_Loans.DPA001Row2 AS VARCHAR(3)) ='Yes' THEN 'Yes' ELSE 'No' END) New_Dpa_Loan,
(CASE WHEN New_Dpa_Loans.total_value_of_new_DPA IS NULL THEN 0.00 ELSE New_Dpa_Loans.total_value_of_new_DPA END) total_value_of_new_DPA,
(CASE WHEN CAST (recovered_dpa_loans.DPA001Row3 AS VARCHAR(3)) = 'Yes' THEN 'Yes' ELSE 'No' END) Recovered_DPA,
(CASE WHEN total_value_of_DPAs_recovered IS NULL THEN 0.00 ELSE total_value_of_DPAs_recovered END) total_value_of_DPAs_recovered  ,
(CASE WHEN CAST(written_off_DPA.dpa_Written_off AS VARCHAR(3)) = 'Yes' Then 'Yes' ELSE 'No' END)  written_off_DPA,
(CASE WHEN amount_written_off IS NULL THEN 0.00 ELSE amount_written_off END) amount_written_off,
dpa_requests.applicationoutcomecode,
dpa_requests.applicationoutcome,
dpa_requests.reason_requested_code,
dpa_requests.reason_requested,
dpa_requests.use_of_property_code, 
dpa_requests.use_of_property,
dpa_requests.secured_with_code,
dpa_requests.secured_with,
NatureOfDPA.primarycontributionarrangecode,
NatureOfDPA.primarycontributionarrangement,
(CASE WHEN NatureOfDPA.Loan_Weekly_Value IS NULL THEN 0.00 ELSE NatureOfDPA.Loan_Weekly_Value END) Loan_Weekly_Value ,
NatureOfDPA.Loan_Weekly_Value_Category,
WrittenOffDPA.finaloutcomecode,
WrittenOffDPA.finaloutcome,
(CASE WHEN WrittenOffDPA.written_off_amount IS NULL THEN 0.00 ELSE WrittenOffDPA.written_off_amount END) written_off_amount  ,
(CASE WHEN WrittenOffDPA.repayment_amount IS NULL THEN 0.00 ELSE WrittenOffDPA.repayment_amount END) repayment_amount ,
RecoveryOfDPA.loan_closed_date ,
RecoveryOfDPA.conclusion_category,
cur_dpa_payments.payments_inc_current_dpas


FROM 

dpaloandetailsview ldv
LEFT JOIN personView pv ON
ldv.personid = pv.personid
LEFT JOIN ( SELECT loanreferencenumber,
                   min(fromdate) loan_activation_date
            FROM dpastatusdetailsview
            WHERE status ='LOAN_ACTIVE'
            GROUP BY loanreferencenumber ) la ON ldv.loanreferencenumber = la.loanreferencenumber
            
LEFT JOIN (SELECT ldv.loanreferencenumber,
           'Yes' DPA001Row1,
            lt.transactions Value_Outstanding_At_End_Date
            FROM 
            dpaloandetailsview ldv
            LEFT JOIN personView pv ON
            ldv.personid = pv.personid

            LEFT JOIN ( SELECT loanreferencenumber, sum(amount) transactions 
                         FROM  dpastatementdetailsview
                         WHERE :END_DATE >= actualdate 
                         GROUP BY loanreferencenumber) lt ON ldv.loanreferencenumber = lt.loanreferencenumber
             
             WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                  FROM dpastatusdetailsview
                                                 WHERE status IN ('LOAN_ACTIVE','LOAN_DEFERRALS_CEASED','LOAN_SETTLEMENT','LOAN_SUSPENDED')
                                                   AND (todate is NULL or todate > :END_DATE
                                                   AND fromdate <= :END_DATE ) )

              AND ldv.loanreferencenumber NOT IN ( SELECT loanreferencenumber
                                                     FROM dpastatusdetailsview
                                                    WHERE status = 'LOAN_CLOSED'
                                                      AND fromdate < :END_DATE ) ) total_value_outstanding ON ldv.loanreferencenumber = total_value_outstanding.loanreferencenumber
LEFT JOIN ( SELECT ldv.loanreferencenumber,
                   'Yes' DPA001Row2,
                    lt.transactions total_value_of_new_DPA
              FROM   dpaloandetailsview ldv
              LEFT JOIN personView pv ON ldv.personid = pv.personid

              LEFT JOIN ( SELECT loanreferencenumber, sum(amount) transactions 
                          FROM  dpastatementdetailsview
                          WHERE :END_DATE >= actualdate 
                          AND transcationtypecode in ('ADJUSTMENT','INTEREST','ADMIN_FEE', 'TOP_UP','CARE_FEE')
                          GROUP BY loanreferencenumber) lt ON ldv.loanreferencenumber = lt.loanreferencenumber
            
              WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                   FROM dpastatusdetailsview
                                                   WHERE status IN ('LOAN_ACTIVE')
                                                    AND fromdate BETWEEN :START_DATE  AND :END_DATE )
                                   
               AND ldv.loanreferencenumber IN (SELECT al.loanreferencenumber
                                                 FROM
                                                (SELECT lsdv.loanreferencenumber,
                                                         max(lsdv.fromdatetime),
                                                         max(lsdv.status) previousStatus,
                                                         lasq.loan_activation_date loan_activation_date
                                                         FROM dpastatusdetailsview lsdv
                                                         LEFT JOIN (SELECT loanreferencenumber,
                                                                           min(fromdate) loan_activation_date
                                                                      FROM dpastatusdetailsview
                                                                     WHERE status ='LOAN_ACTIVE'
                                                                       AND fromdate BETWEEN :START_DATE AND :END_DATE
                                                                       GROUP BY loanreferencenumber ) lasq ON lsdv.loanreferencenumber = lasq.loanreferencenumber
                                                 WHERE lasq.loan_activation_date > lsdv.fromdate
                                                 AND lsdv.status != 'LOAN_ACTIVE'
                                                 GROUP BY lsdv.loanreferencenumber, lasq.loan_activation_date
                                                 ORDER BY lsdv.loanreferencenumber,lasq.loan_activation_date) al
                                                 WHERE al.previousStatus ='LOAN_PRE_ACCOUNT')

               AND ldv.loanreferencenumber NOT IN ( SELECT loanreferencenumber
                                                     FROM dpastatusdetailsview
                                                    WHERE status = 'LOAN_CLOSED'
                                                      AND fromdate < :END_DATE )) New_Dpa_Loans ON ldv.loanreferencenumber = New_Dpa_Loans.loanreferencenumber

LEFT JOIN ( SELECT ldv.loanreferencenumber,
                   'Yes' DPA001Row3
             FROM   dpaloandetailsview ldv
             LEFT JOIN personView pv ON ldv.personid = pv.personid
             WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                  FROM dpastatusdetailsview
                                                 WHERE status IN ('LOAN_CLOSED')
                                                  AND fromdate BETWEEN :START_DATE  AND :END_DATE )
                                   
             AND ldv.loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber 
                                                FROM dpaloandetailsview dpaldv
                                           LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                               WHERE dpasdv.finaloutcomecode ='FULL_VALUE_RECOVERED' ) ) recovered_dpa_loans ON ldv.loanreferencenumber = recovered_dpa_loans.loanreferencenumber




LEFT JOIN (SELECT ldv.loanreferencenumber,
                  lp.payments total_value_of_DPAs_recovered
                  FROM 
                  dpaloandetailsview ldv
                  LEFT JOIN personView pv ON
                  ldv.personid = pv.personid

           LEFT JOIN ( SELECT loanreferencenumber, sum(amount) payments 
                        FROM  dpastatementdetailsview
                        WHERE actualdate BETWEEN :START_DATE  AND :END_DATE  
                          AND transcationtypecode = 'PAYMENT'
                     GROUP BY loanreferencenumber) lp ON ldv.loanreferencenumber = lp.loanreferencenumber ) recovered_dpa_payments ON ldv.loanreferencenumber = recovered_dpa_payments.loanreferencenumber 
                                                                                                   

LEFT JOIN (SELECT ldv.loanreferencenumber,
                  lp.payments_inc_current_dpas payments_inc_current_dpas
                  FROM 
                  dpaloandetailsview ldv
                  LEFT JOIN personView pv ON
                  ldv.personid = pv.personid

           LEFT JOIN ( SELECT loanreferencenumber, 'Yes' payments_inc_current_dpas 
                        FROM  dpastatementdetailsview
                        WHERE actualdate BETWEEN :START_DATE  AND :END_DATE  
                          AND transcationtypecode = 'PAYMENT'
                     GROUP BY loanreferencenumber) lp ON ldv.loanreferencenumber = lp.loanreferencenumber   

                     WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                          FROM dpastatusdetailsview
                                                         WHERE status IN ('LOAN_ACTIVE','LOAN_DEFERRALS_CEASED','LOAN_SUSPENDED')
                                                           AND (todate is NULL or todate > :END_DATE )
                                                           AND fromdate <= :END_DATE  )
                                                           AND ldv.loanreferencenumber NOT IN ( SELECT loanreferencenumber
                                                                                                  FROM dpastatusdetailsview
                                                                                                 WHERE status IN ('LOAN_CLOSED','LOAN_SETTLEMENT')
                                                                                                   AND fromdate < :END_DATE )) cur_dpa_payments ON ldv.loanreferencenumber = cur_dpa_payments.loanreferencenumber

LEFT JOIN (SELECT ldv.loanreferencenumber,
          'Yes' dpa_Written_off,
           wo.amount_written_off
           FROM 
           dpaloandetailsview ldv
           LEFT JOIN personView pv ON
           ldv.personid = pv.personid
           LEFT JOIN ( SELECT loanreferencenumber, sum(amount) amount_written_off 
                        FROM  dpastatementdetailsview
                        WHERE actualdate BETWEEN :START_DATE  AND :END_DATE 
                          AND transcationtypecode = 'WRITE_OFF'
                     GROUP BY loanreferencenumber) wo ON ldv.loanreferencenumber = wo.loanreferencenumber
           
            
           WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                FROM dpastatusdetailsview
                                               WHERE status IN ('LOAN_CLOSED')
                                                AND fromdate BETWEEN :START_DATE  AND :END_DATE )
                                   
           AND ldv.loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber 
                                              FROM dpaloandetailsview dpaldv
                                              LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                              WHERE dpasdv.finaloutcomecode IN ('RECOVERY_NOT_ATTEMPTED','RECOVERY_ATTEMPTED_NO_VALUE','RECOVERY_ATTEMPTED_PARTIAL_VALUE' ) ) ) written_off_DPA  ON ldv.loanreferencenumber = written_off_DPA.loanreferencenumber   


LEFT JOIN (SELECT ldv.loanreferencenumber,
                  ldv.applicationoutcomecode,
                  ldv.applicationoutcome,
                  activeCohort.loan_activation_date,
                  NULL loan_abandoned_date,
                  ldv.reasonrequestedcode reason_requested_code,
                  ldv.reasonrequested reason_requested,
                  useofproperty.useofpropertyduringloancode use_of_property_code, 
                  useofproperty.useofpropertyduringloan use_of_property,
                  securedwith.securedwithcode secured_with_code,
                  securedwith.securedwith secured_with
                  FROM 
                  dpaloandetailsview ldv 

           LEFT JOIN personView pv ON ldv.personid = pv.personid

           LEFT JOIN (SELECT lsdv.loanreferencenumber,
                             max(lsdv.fromdatetime),
                             max(lsdv.status) previousStatus,
                             lasq.loan_activation_date loan_activation_date
                      FROM dpastatusdetailsview lsdv

                      LEFT JOIN (SELECT loanreferencenumber,
                                        min(fromdate) loan_activation_date
                                 FROM dpastatusdetailsview
                                 WHERE status ='LOAN_ACTIVE'
                                  AND fromdate BETWEEN :START_DATE  AND :END_DATE
                                 GROUP BY loanreferencenumber ) lasq ON lsdv.loanreferencenumber = lasq.loanreferencenumber
           
                       WHERE lasq.loan_activation_date > lsdv.fromdate
                       AND lsdv.status != 'LOAN_ACTIVE'
                       GROUP BY lsdv.loanreferencenumber, lasq.loan_activation_date
                       ORDER BY lsdv.loanreferencenumber,lasq.loan_activation_date) activeCohort ON ldv.loanreferencenumber = activeCohort.loanreferencenumber

           LEFT JOIN (SELECT loanreferencenumber, 
                             useofpropertyduringloancode, 
                             useofpropertyduringloan 
                        FROM dpaassetdetailsview ) useofproperty ON ldv.loanreferencenumber = useofproperty.loanreferencenumber

           LEFT JOIN (SELECT adv.loanreferencenumber,
                              cddv.securedwithcode,
                              cddv.securedwith
                       FROM   dpachargesdeducteddetailsview cddv
                      LEFT JOIN dpaassetdetailsview adv ON cddv.assetid = adv.assetid ) securedwith ON ldv.loanreferencenumber = securedwith.loanreferencenumber 


            WHERE activeCohort.previousStatus ='LOAN_PRE_ACCOUNT'

            UNION

            SELECT ldv.loanreferencenumber,
                   ldv.applicationoutcomecode,
                   ldv.applicationoutcome,
                   NULL loan_activation_date,
                   abandonedCohort.loan_abandoned_date,
                   NULL reason_requested_code,
                   NULL reason_requested,
                   NULL use_of_property_code, 
                   NULL use_of_property,
                   NULL secured_with_code,
                   NULL secured_with
                   FROM 
                   dpaloandetailsview ldv 

            LEFT JOIN personView pv ON ldv.personid = pv.personid

            JOIN (SELECT loanreferencenumber,
                         fromdate loan_abandoned_date
                    FROM dpastatusdetailsview
                   WHERE status ='APPLICATION_ABANDONED'
                     AND fromdate BETWEEN :START_DATE  AND :END_DATE  ) abandonedCohort ON ldv.loanreferencenumber = abandonedCohort.loanreferencenumber) dpa_requests ON ldv.loanreferencenumber = dpa_requests.loanreferencenumber


----    

LEFT JOIN (SELECT ldv.loanreferencenumber,
                  ldv.primarycontributionarrangecode,
                  ldv.primarycontributionarrangement,
                  (CASE WHEN lt.transactions IS NULL THEN 0 ELSE lt.transactions END) Loan_Weekly_Value,
                  (CASE WHEN lt.transactions < 300 OR lt.transactions IS NULL THEN 'Less than £300'
                        WHEN lt.transactions >= 300 AND lt.transactions <= 400 THEN '£300 - £400'
                        WHEN lt.transactions > 400 AND lt.transactions <= 500 THEN '£400 - £500'
                        WHEN lt.transactions > 500 THEN 'Greater than £500' END) Loan_Weekly_Value_Category
             FROM dpaloandetailsview ldv 
             LEFT JOIN personView pv ON ldv.personid = pv.personid
             LEFT JOIN ( SELECT dsv.loanreferencenumber, sum(amount) transactions 
                          FROM  dpastatementdetailsview dsv
                          LEFT JOIN (SELECT loanreferencenumber, max(CASE WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2015' AS DATE) AND CAST( '31-MAR-2016' AS DATE) THEN CAST( '25-MAR-2016' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2016' AS DATE) AND CAST( '31-MAR-2017' AS DATE) THEN CAST( '25-MAR-2017' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2017' AS DATE) AND CAST( '31-MAR-2018' AS DATE) THEN CAST( '25-MAR-2018' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2018' AS DATE) AND CAST( '31-MAR-2019' AS DATE) THEN CAST( '25-MAR-2019' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2019' AS DATE) AND CAST( '31-MAR-2020' AS DATE) THEN CAST( '25-MAR-2020' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2020' AS DATE) AND CAST( '31-MAR-2021' AS DATE) THEN CAST( '25-MAR-2021' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2021' AS DATE) AND CAST( '31-MAR-2022' AS DATE) THEN CAST( '25-MAR-2022' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2022' AS DATE) AND CAST( '31-MAR-2023' AS DATE) THEN CAST( '25-MAR-2023' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2023' AS DATE) AND CAST( '31-MAR-2024' AS DATE) THEN CAST( '25-MAR-2024' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2024' AS DATE) AND CAST( '31-MAR-2025' AS DATE) THEN CAST( '25-MAR-2025' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2025' AS DATE) AND CAST( '31-MAR-2026' AS DATE) THEN CAST( '25-MAR-2026' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2026' AS DATE) AND CAST( '31-MAR-2027' AS DATE) THEN CAST( '25-MAR-2027' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2027' AS DATE) AND CAST( '31-MAR-2028' AS DATE) THEN CAST( '25-MAR-2028' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2028' AS DATE) AND CAST( '31-MAR-2029' AS DATE) THEN CAST( '25-MAR-2029' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2029' AS DATE) AND CAST( '31-MAR-2030' AS DATE) THEN CAST( '25-MAR-2030' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2030' AS DATE) AND CAST( '31-MAR-2031' AS DATE) THEN CAST( '25-MAR-2031' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2031' AS DATE) AND CAST( '31-MAR-2032' AS DATE) THEN CAST( '25-MAR-2032' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2032' AS DATE) AND CAST( '31-MAR-2033' AS DATE) THEN CAST( '25-MAR-2033' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2033' AS DATE) AND CAST( '31-MAR-2034' AS DATE) THEN CAST( '25-MAR-2034' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2034' AS DATE) AND CAST( '31-MAR-2035' AS DATE) THEN CAST( '25-MAR-2035' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2035' AS DATE) AND CAST( '31-MAR-2036' AS DATE) THEN CAST( '25-MAR-2036' AS DATE)
                                                                          WHEN CAST(:END_DATE  AS DATE) BETWEEN CAST( '01-APR-2036' AS DATE) AND CAST( '31-MAR-2037' AS DATE) THEN CAST( '25-MAR-2037' AS DATE)
                                                                     END) startDate
                                     FROM dpastatementdetailsview
                                     GROUP BY loanreferencenumber ) stdate ON dsv.loanreferencenumber = stdate.loanreferencenumber

              LEFT JOIN (SELECT loanreferencenumber, max(CASE WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2015' AS DATE) AND CAST( '31-MAR-2016' AS DATE) THEN CAST( '31-MAR-2016' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2016' AS DATE) AND CAST( '31-MAR-2017' AS DATE) THEN CAST( '31-MAR-2017' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2017' AS DATE) AND CAST( '31-MAR-2018' AS DATE) THEN CAST( '31-MAR-2018' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2018' AS DATE) AND CAST( '31-MAR-2019' AS DATE) THEN CAST( '31-MAR-2019' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2019' AS DATE) AND CAST( '31-MAR-2020' AS DATE) THEN CAST( '31-MAR-2020' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2020' AS DATE) AND CAST( '31-MAR-2021' AS DATE) THEN CAST( '31-MAR-2021' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2021' AS DATE) AND CAST( '31-MAR-2022' AS DATE) THEN CAST( '31-MAR-2022' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2022' AS DATE) AND CAST( '31-MAR-2023' AS DATE) THEN CAST( '31-MAR-2023' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2023' AS DATE) AND CAST( '31-MAR-2024' AS DATE) THEN CAST( '31-MAR-2024' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2024' AS DATE) AND CAST( '31-MAR-2025' AS DATE) THEN CAST( '31-MAR-2025' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2025' AS DATE) AND CAST( '31-MAR-2026' AS DATE) THEN CAST( '31-MAR-2026' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2026' AS DATE) AND CAST( '31-MAR-2027' AS DATE) THEN CAST( '31-MAR-2027' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2027' AS DATE) AND CAST( '31-MAR-2028' AS DATE) THEN CAST( '31-MAR-2028' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2028' AS DATE) AND CAST( '31-MAR-2029' AS DATE) THEN CAST( '31-MAR-2029' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2029' AS DATE) AND CAST( '31-MAR-2030' AS DATE) THEN CAST( '31-MAR-2030' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2030' AS DATE) AND CAST( '31-MAR-2031' AS DATE) THEN CAST( '31-MAR-2031' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2031' AS DATE) AND CAST( '31-MAR-2032' AS DATE) THEN CAST( '31-MAR-2032' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2032' AS DATE) AND CAST( '31-MAR-2033' AS DATE) THEN CAST( '31-MAR-2033' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2033' AS DATE) AND CAST( '31-MAR-2034' AS DATE) THEN CAST( '31-MAR-2034' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2034' AS DATE) AND CAST( '31-MAR-2035' AS DATE) THEN CAST( '31-MAR-2035' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2035' AS DATE) AND CAST( '31-MAR-2036' AS DATE) THEN CAST( '31-MAR-2036' AS DATE)
                                                              WHEN CAST( :END_DATE  AS DATE) BETWEEN CAST( '01-APR-2036' AS DATE) AND CAST( '31-MAR-2037' AS DATE) THEN CAST( '31-MAR-2037' AS DATE)
                                                         END) endDate
                       FROM dpastatementdetailsview
                       GROUP BY loanreferencenumber  ) endate ON dsv.loanreferencenumber = endate.loanreferencenumber

        WHERE transcationtypecode in ('INTEREST','ADMIN_FEE', 'TOP_UP','CARE_FEE')
        AND actualdate BETWEEN stdate.startDate AND endate.endDate    
        GROUP BY dsv.loanreferencenumber) lt ON ldv.loanreferencenumber = lt.loanreferencenumber 
           
WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                   FROM dpastatusdetailsview
                                   WHERE status IN ('LOAN_ACTIVE','LOAN_DEFERRALS_CEASED','LOAN_SETTLEMENT','LOAN_SUSPENDED')
                                   AND (todate is NULL or todate > :END_DATE )
                                   AND fromdate <= :END_DATE  ) ) NatureOfDPA ON ldv.loanreferencenumber = NatureOfDPA.loanreferencenumber  

LEFT JOIN (SELECT ldv.loanreferencenumber,
                  lc.loan_closed_date,
                  (CASE WHEN pv.dieddate IS NULL OR pv.dieddate > :END_DATE  THEN 'CONCLUDED DURING LIFETIME' ELSE 'CONCLUDED DUE TO DEATH' END) conclusion_category
             FROM dpaloandetailsview ldv 
             LEFT JOIN personView pv ON ldv.personid = pv.personid
             LEFT JOIN (SELECT lsdv.loanreferencenumber,
                                max(lsdv.fromdatetime),
                                max(lsdv.status) previousStatus,
                                lasq.loan_activation_date loan_activation_date,
                                max(lcd.loan_closed_date) loan_closed_date
                        FROM dpastatusdetailsview lsdv
                        LEFT JOIN (SELECT loanreferencenumber,
                                          min(fromdate) loan_activation_date
                                    FROM dpastatusdetailsview
                                   WHERE status ='LOAN_ACTIVE'
                                   GROUP BY loanreferencenumber ) lasq ON lsdv.loanreferencenumber = lasq.loanreferencenumber


                        LEFT JOIN (SELECT loanreferencenumber,
                                          min(fromdate) loan_closed_date
                                     FROM dpastatusdetailsview
                                     WHERE status ='LOAN_CLOSED'
                                      AND fromdate BETWEEN :START_DATE  AND :END_DATE 
                                     GROUP BY loanreferencenumber ) lcd ON lsdv.loanreferencenumber = lcd.loanreferencenumber

                        WHERE lasq.loan_activation_date > lsdv.fromdate
                          AND lsdv.status != 'LOAN_ACTIVE'
                     GROUP BY lsdv.loanreferencenumber, lasq.loan_activation_date
                     ORDER BY lsdv.loanreferencenumber,lasq.loan_activation_date) lc ON ldv.loanreferencenumber = lc.loanreferencenumber

       WHERE lc.previousStatus ='LOAN_PRE_ACCOUNT'
         AND lc.loan_closed_date BETWEEN :START_DATE  AND :END_DATE 
         AND ldv.loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber 
                                            FROM dpaloandetailsview dpaldv
                                         LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                         WHERE dpasdv.finaloutcomecode ='FULL_VALUE_RECOVERED' ))  RecoveryOfDPA ON ldv.loanreferencenumber = RecoveryOfDPA.loanreferencenumber  


LEFT JOIN ( SELECT ldv.loanreferencenumber,
                   lsv.finaloutcomecode,
                   lsv.finaloutcome,
                   lt.written_off_amount,
                   lr.repayment_amount
            FROM   dpaloandetailsview ldv
            LEFT JOIN personView pv ON ldv.personid = pv.personid
            LEFT JOIN ( SELECT loanreferencenumber,
                                min(fromdate) loan_activation_date
                          FROM dpastatusdetailsview
                         WHERE status ='LOAN_ACTIVE'
                       GROUP BY loanreferencenumber ) la ON ldv.loanreferencenumber = la.loanreferencenumber
            
            JOIN      ( SELECT dpaldv.loanreferencenumber,
                                dpasdv.finaloutcomecode,
                                dpasdv.finaloutcome
                           FROM dpaloandetailsview dpaldv
                           LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                         WHERE dpasdv.finaloutcomecode in ('RECOVERY_ATTEMPTED_NO_VALUE','RECOVERY_ATTEMPTED_PARTIAL_VALUE' ,'RECOVERY_NOT_ATTEMPTED','FULL_VALUE_RECOVERED')) lsv ON ldv.loanreferencenumber = lsv.loanreferencenumber

           LEFT JOIN ( SELECT loanreferencenumber, sum(amount) written_off_amount
                         FROM dpastatementdetailsview
                        WHERE transcationtypecode = 'WRITE_OFF'
                          AND actualdate BETWEEN :START_DATE  AND :END_DATE 
                          AND loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber
                                                         FROM dpaloandetailsview dpaldv
                                                         LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                                        WHERE dpasdv.finaloutcomecode in ('RECOVERY_ATTEMPTED_NO_VALUE','RECOVERY_ATTEMPTED_PARTIAL_VALUE'))
             
             GROUP BY loanreferencenumber

             UNION

             SELECT loanreferencenumber, sum(amount) written_off_amount
             FROM  dpastatementdetailsview
             WHERE transcationtypecode in ('WRITE_OFF')
             AND actualdate BETWEEN :START_DATE  AND :END_DATE 
             AND loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber
                                            FROM dpaloandetailsview dpaldv
                                            LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                            WHERE dpasdv.finaloutcomecode in ('RECOVERY_NOT_ATTEMPTED'))
                                            GROUP BY loanreferencenumber ) lt ON ldv.loanreferencenumber = lt.loanreferencenumber 

             LEFT JOIN  (SELECT loanreferencenumber, sum(amount) repayment_amount
                          FROM  dpastatementdetailsview
                          WHERE transcationtypecode in ('PAYMENT')
                            AND actualdate BETWEEN :START_DATE  AND :END_DATE 
                            AND loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber
                                                           FROM dpaloandetailsview dpaldv
                                                           LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                                          WHERE dpasdv.finaloutcomecode in ('RECOVERY_ATTEMPTED_PARTIAL_VALUE'))
             GROUP BY loanreferencenumber ) lr ON ldv.loanreferencenumber = lr.loanreferencenumber           

             WHERE ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                                  FROM dpastatusdetailsview
                                                 WHERE status IN ('LOAN_CLOSED')
                                                   AND fromdate BETWEEN :START_DATE  AND :END_DATE )) WrittenOffDPA ON ldv.loanreferencenumber = WrittenOffDPA.loanreferencenumber                         

            
WHERE 

(ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                   FROM dpastatusdetailsview
                                   WHERE status IN ('LOAN_ACTIVE','LOAN_DEFERRALS_CEASED','LOAN_SETTLEMENT','LOAN_SUSPENDED')
                                   AND (todate is NULL or todate > :END_DATE )
                                   AND fromdate <= '31-MAR-2017' )

AND ldv.loanreferencenumber NOT IN ( SELECT loanreferencenumber
                                   FROM dpastatusdetailsview
                                   WHERE status = 'LOAN_CLOSED'
                                   AND fromdate < :END_DATE ))

OR                                   

(ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                   FROM dpastatusdetailsview
                                   WHERE status IN ('LOAN_ACTIVE')
                                   AND fromdate BETWEEN :START_DATE  AND :END_DATE )
                                   
AND ldv.loanreferencenumber IN (SELECT al.loanreferencenumber
                                 FROM
                                (SELECT lsdv.loanreferencenumber,
                                         max(lsdv.fromdatetime),
                                         max(lsdv.status) previousStatus,
                                         lasq.loan_activation_date loan_activation_date
                                         FROM dpastatusdetailsview lsdv

                                 LEFT JOIN (SELECT loanreferencenumber,
                                                    min(fromdate) loan_activation_date
                                             FROM dpastatusdetailsview
                                             WHERE status ='LOAN_ACTIVE'
                                             AND fromdate BETWEEN :START_DATE  AND :END_DATE 
                                             GROUP BY loanreferencenumber ) lasq ON lsdv.loanreferencenumber = lasq.loanreferencenumber
                                 WHERE lasq.loan_activation_date > lsdv.fromdate
                                 AND lsdv.status != 'LOAN_ACTIVE'
                                 GROUP BY lsdv.loanreferencenumber, lasq.loan_activation_date
                                 ORDER BY lsdv.loanreferencenumber,lasq.loan_activation_date) al
                                 WHERE al.previousStatus ='LOAN_PRE_ACCOUNT') )  
OR

(ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                   FROM dpastatusdetailsview
                                   WHERE status IN ('LOAN_CLOSED')
                                   AND fromdate BETWEEN :START_DATE  AND :END_DATE )
                                   
AND ldv.loanreferencenumber IN ( SELECT dpaldv.loanreferencenumber 
                                 FROM dpaloandetailsview dpaldv
                                 LEFT JOIN dpasettlementdetailsview dpasdv ON dpaldv.settlementid = dpasdv.settlementid
                                 WHERE dpasdv.finaloutcomecode IN ('FULL_VALUE_RECOVERED','RECOVERY_NOT_ATTEMPTED','RECOVERY_ATTEMPTED_NO_VALUE','RECOVERY_ATTEMPTED_PARTIAL_VALUE') ))
                                 
OR (ldv.loanreferencenumber IN ( SELECT loanreferencenumber
                                  FROM dpastatusdetailsview
                                 WHERE status ='APPLICATION_ABANDONED'
                                   AND fromdate BETWEEN :START_DATE  AND :END_DATE  ))
                                   
AND ldv.typeofloan IN ('MANDATORY SCHEME','DISCRETIONARY SCHEME')




