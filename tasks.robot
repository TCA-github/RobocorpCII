*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orderurl}=    Get url from vault
    Open the robot order website    ${orderurl}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10s    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
#    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    [Arguments]    ${site}
    Open Available Browser    ${site}
#Ask user url
#    Add text input    address    label=Give url
#    ${response}=    Run dialog
#    [Return]    ${url}

Get url from vault
    ${secret}=    Get Secret    link
    [Return]    ${secret}[url]

Close the annoying modal
    Click Button    Yep

Download the csvfile
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    Download the csvfile
    ${orders} =    Read table from CSV    orders.csv
    [Return]    ${orders}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Element Is Visible    id:order-completion    3s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_completion_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_completion_html}    ${OUTPUT_DIR}${/}order-number-${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot${order_number}.png
    Open Pdf    ${OUTPUT_DIR}${/}order-number-${order_number}.pdf
    ${files}=    Create List    ${OUTPUT_DIR}${/}robot${order_number}.png
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}order-number-${order_number}.pdf    append=True
    Close Pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${CURDIR}${/}    ${CURDIR}${/}receiptsarchive.zip    recursive=True    include=*.pdf
