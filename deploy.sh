cd ansible
export AZURE_RESOURCE_GROUPS=rg_vmonly
export AZURE_TAGS=bcd_stackId:vmonly_from
ansible-playbook -i inventory/azure/azure_wrapper.sh -e "@scenarios/migration_azure_vm_vnet1.yml" -e "bcd_stack_id=vmonly_from" undeploy_stack.yml
export AZURE_TAGS=bcd_stackId:vmonly_to
ansible-playbook -i inventory/azure/azure_wrapper.sh -e "@scenarios/migration_azure_vm_vnet2.yml" -e "bcd_stack_id=vmonly_to" undeploy_stack.yml

export AZURE_TAGS=bcd_stackId:vmonly_from
ansible-playbook -i inventory/azure/azure_wrapper.sh -e "@scenarios/migration_azure_vm_vnet1.yml" -e "bcd_stack_id=vmonly_from" deploy_stack.yml
export AZURE_TAGS=bcd_stackId:vmonly_to
ansible-playbook -i inventory/azure/azure_wrapper.sh -e "@scenarios/migration_azure_vm_vnet2.yml" -e "bcd_stack_id=vmonly_to" deploy_stack.yml

echo "You can launch tests here : http://migration-test-benchflow.westeurope.cloudapp.azure.com:9980"
