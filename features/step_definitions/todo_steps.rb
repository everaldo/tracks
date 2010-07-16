Given /^I have no todos$/ do
  Todo.delete_all
end

Given /^I have ([0-9]+) todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context A")
  count.to_i.downto 1 do |i|
    @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}")
  end
end

Given /^I have ([0-9]+) deferred todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context B")
  count.to_i.downto 1 do |i|
    @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}", :show_from => @current_user.time + 1.week)
  end
end

Given /^I have ([0-9]+) completed todos$/ do |count|
  context = @current_user.contexts.create!(:name => "context C")
  count.to_i.downto 1 do |i|
    todo = @current_user.todos.create!(:context_id => context.id, :description => "todo #{i}")
    todo.complete!
  end
end

Given /^"(.*)" depends on "(.*)"$/ do |successor_name, predecessor_name|
  successor = Todo.find_by_description(successor_name)
  predecessor = Todo.find_by_description(predecessor_name)
  
  successor.add_predecessor(predecessor)
  successor.state = "pending"
  successor.save!
end

When /^I drag "(.*)" to "(.*)"$/ do |dragged, target|
  drag_id = Todo.find_by_description(dragged).id
  drop_id = Todo.find_by_description(target).id
  drag_name = "xpath=//div[@id='line_todo_#{drag_id}']//img[@class='grip']"
  drop_name = "xpath=//div[@id='line_todo_#{drop_id}']//div[@class='description']"
  
  selenium.drag_and_drop_to_object(drag_name, drop_name)

  arrow = "xpath=//div[@id='line_todo_#{drop_id}']/div/a[@class='show_successors']/img"
  selenium.wait_for_element(arrow)
end

When /^I expand the dependencies of "([^\"]*)"$/ do |todo_name|
  todo = Todo.find_by_description(todo_name)
  todo.should_not be_nil

  expand_img_locator = "xpath=//div[@id='line_todo_#{todo.id}']/div/a[@class='show_successors']/img"
  selenium.click(expand_img_locator)
end

Then /^I should see ([0-9]+) todos$/ do |count|
  count.to_i.downto 1 do |i|
    match_xpath "div["
  end
end

When /I change the (.*) field of "([^\"]*)" to "([^\"]*)"$/ do |field, todo_name, new_value|
  selenium.click("//span[@class=\"todo.descr\"][.=\"#{todo_name}\"]/../../a[@class=\"icon edit_item\"]", :wait_for => :ajax, :javascript_framework => :jquery)
  selenium.type("css=form.edit_todo_form input[name=#{field}]", new_value)
  selenium.click("css=button.positive", :wait_for => :ajax, :javascript_framework => :jquery)
  sleep(5)
end

When /^I submit a new action with description "([^"]*)"$/ do |description|
  fill_in "todo[description]", :with => description
  selenium.click("xpath=//form[@id='todo-form-new-action']//button[@id='todo_new_action_submit']", :wait_for => :ajax, :javascript_framework => :jquery)
end

When /^I submit multiple actions with using$/ do |multiple_actions|
  fill_in "todo[multiple_todos]", :with => multiple_actions
  selenium.click("xpath=//form[@id='todo-form-multi-new-action']//button[@id='todo_multi_new_action_submit']", :wait_for => :ajax, :javascript_framework => :jquery)
end

When /^I fill the multiple actions form with "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)"$/ do |descriptions, project_name, context_name, tags|
  fill_in "todo[multiple_todos]", :with => descriptions
  fill_in "multi_todo_project_name", :with => project_name
  fill_in "multi_todo_context_name", :with => context_name
  fill_in "multi_tag_list", :with => tags
end

When /^I submit the new multiple actions form with "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)"$/ do |descriptions, project_name, context_name, tags|
  When "I fill the multiple actions form with \"#{descriptions}\", \"#{project_name}\", \"#{context_name}\", \"#{tags}\""
  selenium.click("xpath=//form[@id='todo-form-multi-new-action']//button[@id='todo_multi_new_action_submit']", :wait_for => :ajax, :javascript_framework => :jquery)
end

When /^I submit the new multiple actions form with$/ do |multi_line_descriptions|
  fill_in "todo[multiple_todos]", :with => multi_line_descriptions
  selenium.click("xpath=//form[@id='todo-form-multi-new-action']//button[@id='todo_multi_new_action_submit']", :wait_for => :ajax, :javascript_framework => :jquery)
end



Then /^the dependencies of "(.*)" should include "(.*)"$/ do |child_name, parent_name|
  parent = @current_user.todos.find_by_description(parent_name)
  parent.should_not be_nil
  
  child = parent.pending_successors.find_by_description(child_name)
  child.should_not be_nil
end

Then /^I should see "([^\"]*)" within the dependencies of "([^\"]*)"$/ do |successor_description, todo_description|
  todo = @current_user.todos.find_by_description(todo_description)
  todo.should_not be_nil
  successor = @current_user.todos.find_by_description(successor_description)
  successor.should_not be_nil

  # argh, webrat on selenium does not support within, so this won't work
  # xpath = "//div[@id='line_todo_#{todo.id}'"
  # Then "I should see \"#{successor_description}\" within \"xpath=#{xpath}\""

  # let selenium look for the presence of the successor
  xpath = "xpath=//div[@id='line_todo_#{todo.id}']//div[@id='successor_line_todo_#{successor.id}']//span"
  selenium.wait_for_element(xpath, :timeout_in_seconds => 5)
end

Then /^I should see the todo "([^\"]*)"$/ do |todo_description|
  selenium.is_element_present("//span[.=\"#{todo_description}\"]").should be_true
end

Then /^I should not see the todo "([^\"]*)"$/ do |todo_description|
  selenium.is_element_present("//span[.=\"#{todo_description}\"]").should be_false
end

Then /^the number of actions should be (\d+)$/ do |count|
  @current_user.todos.count.should == count.to_i
end
