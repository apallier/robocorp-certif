*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Playwright    WITH NAME    Browser
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    Dialogs

# +
*** Keywords ***
Open the robot order website
    Browser.New Browser    chromium    headless=false
    Browser.New Context    viewport={'width': 1920, 'height': 1080}
    Browser.New Page       https://robotsparebinindustries.com/#/robot-order

Get Orders
    ${order_url}=    Dialogs.Get Value From User    Please, enter order URL   https://robotsparebinindustries.com/orders.csv
    RPA.HTTP.Download    ${order_url}    orders.csv    overwrite=${TRUE}
    ${table}=    RPA.Tables.Read table from CSV     orders.csv    headers=${TRUE}
    [Return]    ${table}

Close the annoying modal
    Browser.Click    //button[contains(.,'I guess so...')]

Fill the form
    [Arguments]    ${row}
    Browser.Select Options By    select[id=head]    value    ${row}[Head]
    Browser.Check Checkbox    id=id-body-${row}[Body]
    Browser.Fill Text    //label[contains(.,'3. Legs:')]/../input    ${row}[Legs]
    Browser.Fill Text    id=address    ${row}[Address]

Preview the robot
    Browser.Click    id=preview
    
Submit the order
    ${old_timeout} =    Browser.Set Browser Timeout    1s
    Browser.Click    id=order
    Browser.Get Element    id=order-another
    [Teardown]    Browser.Set Browser Timeout    ${old_timeout}
    
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt}=    Browser.Get Property    id=receipt    outerHTML
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    RPA.PDF.Html To Pdf    ${receipt}    ${pdf}
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}=    Browser.Take Screenshot    ${OUTPUT_DIR}${/}screenshots/${order_number}    id=robot-preview-image
    [Return]    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}    
    RPA.PDF.Add Files To Pdf     ${files}     ${pdf}    append=${TRUE}

Go to order another robot
    Browser.Click    id=order-another
    
Create a ZIP file of the receipts
    RPA.Archive.Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    receipts.zip    recursive=${TRUE}
    
# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds     10x    0.1s      Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
