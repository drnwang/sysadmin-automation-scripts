@{
    # Rules checked by the CI pipeline. Errors fail the build; warnings are reported.
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # These are interactive admin scripts; Write-Host is used deliberately for colored status messages.
        'PSAvoidUsingWriteHost'
    )
}
