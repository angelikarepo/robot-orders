*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.Desktop
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc...
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Check if order is submitted
        Check for error messages
        ${pdf}=Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    robotpage
    Open Available Browser    ${secret}[link]

Get orders link

Get orders
    Add text input    input    label=Provide orders link
    ${response}=    Run dialog
    Download    ${response.input}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order

Check if order is submitted
    ${order}=    Is Element Visible    id:receipt
    IF    ${order} == ${False}    Submit the order    ELSE    No Operation

Check for error messages
    ${error}=    Is Element Visible    class:alert-danger
    IF    ${error} == ${True}    Submit the order    ELSE    No Operation

Store the receipt as a PDF file
    [Arguments]    ${row}
    Check for error messages
    ${orderhtml}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${orderhtml}    ${OUTPUT_DIR}${/}receipts${/}receipt${row}.pdf
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt${row}.pdf
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robots${/}robot${row}.png
    ${screenshot}=    Set Variable    ${OUTPUT_DIR}${/}robots${/}robot${row}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    ${screenshot}=    Create List    ${screenshot}
    Add Files To Pdf    ${screenshot}    ${pdf}    append:${True}
    Close Pdf

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}
