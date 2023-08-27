import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";

import RailscollabHelpers from "helpers/railscollab_helpers";

// Main page controller
export default class extends Controller
{
  init() {
    var us = this;

    var node = document.querySelector('meta[name="project-id"]');
    this.PROJECT_ID = node ? node.getAttribute("content") : null;
    node = document.querySelector('meta[name="user-id"]');
    this.USER_ID = node ? node.getAttribute("content") : null;

    this.Project = {
      buildUrl: function(resource) {
        return ('/projects/' + us.PROJECT_ID + resource);
      },

      updateRunningTimes: function(size, locale) {
        $('#running_times_count span').html(locale);

        if (size > 0)
        {
          $('#running_times_count').show();
        }
        else 
        {
          $('#running_times_count').hide();
          $('#running_times_menu').hide();
        }
      }
    };

    // Login form stuff
    // Permissions form stuff
    this.permissions_form_items = [];

    // Notification form stuff (mainly for message posting)
    this.notify_form_companies = {};

    // File form stuff
    this.file_form_controls = null;

    this.staticBoundEvents = [];
    this.dynamicBoundEvents = [];
    this.listItemSortables = null;
  }

  connect() {
    this.init();
    this.bindStatic();
    this.bindDynamic();
  }

  disconnect() {
    this.clearDynamicEvents();
    this.clearStaticEvents();
  }

  bindDynamicEvent(el, name, func) {
    this.dynamicBoundEvents.push([el, name, func]);
    el.on(name, func);
  }

  bindStaticEvent(el, name, func) {
    this.staticBoundEvents.push([el, name, func]);
    el.on(name, func);
  }

  clearDynamicEvents() {
    this.dynamicBoundEvents.forEach((item) => {
      item[0].off(item[1], item[2]);
    });
    this.dynamicBoundEvents = [];
  }

  clearStaticEvents() {
    this.staticBoundEvents.forEach((item) => {
      item[0].off(item[1], item[2]);
    });
    this.staticBoundEvents = [];
  }


  bindStatic() {

    var controller = this;

    this.bindStaticEvent($('.flash_success, .flash_error', 'click'), function(evt) {
      $(this).hide('slow');

      return false;
    });

    this.bindStaticEvent($('.ajax_action', 'click'), function(evt) {
      RailsCollabHelpers.get($(this).attr('href'), {},
        JustRebind, 'script');

      return false;
    });

    this.bindStaticEvent($('a#messageFormAdditionalTextToggle'), 'click', function(evt) {

      if ($('#messageFormAdditionalText').css('display') == 'none')
      {
        $('#messageFormAdditionalText').show();
        $('#messageFormAdditionalTextExpand').show();
        $('#messageFormAdditionalTextCollapse').show();
      }
      else
      {
        $('#messageFormAdditionalText').hide();
        $('#messageFormAdditionalTextExpand').hide();
        $('#messageFormAdditionalTextCollapse').hide();
      }

      return false;
    });

    this.bindStaticEvent($('.taskCheckbox .completion'), 'click', function(evt) {
      var el = $(evt.target);
      var url = el.next('a').attr('href');

      RailsCollabHelpers.put(url, {
        'task[completed]': evt.target.checked
      },
      JustReload, 'script');

      return false;
    });

    this.bindStaticEvent($('.PopupMenuWidgetAttachTo'), 'click', function(evt) {
      $(this).title = '';
      var menu = $('#' + this.id + '_menu');
      var shouldShow = true;

      if (menu.css('display') != 'none') {
        shouldShow = false;
      }

      $('.PopupMenuWidgetDiv').each((idx, el) => {
        $(el).hide();
      });

      if (shouldShow)
      {
        menu.show();
      }
    });
  }

  startLoading(evt) {
    $(evt.target).addClass('loading')
    .find('input, select, textarea, button').attr('disabled', 'disabled');
  }

  stopLoading(evt, evt2, evt3, evt4) {
    $(evt.target).removeClass('loading')
    .find('input, select, textarea, button').attr('disabled', null);
  }

  startLoadingForm(evt) {
    $(evt.target).parents('form:first').addClass('loading')
    .find('input, select, textarea, button').attr('disabled', 'disabled');
  }

  stopLoadingForm(evt) {
    $(evt.target).parents('form:first').removeClass('loading')
    .find('input, select, textarea, button').attr('disabled', null);
  }

  replaceTask(data, content) {
    var task = $('#task_item_' + data.id);
    var in_list = task.parents('.taskItems:first').parent();

      // Replace or insert into correct list
    if (data.task_class != null && !in_list.hasClass(data.task_class)) {
      var task_list = task.parents('.taskList:first');
      task_list.find('.' + data.task_class + ' .taskItems:first').append(task);
    }

    if (content)
      task.html(data.content);
    else
      task.replaceWith(data.content);
  }

  reloadTask(data) {
    RailsCollabHelpers.get('/projects/' + this.PROJECT_ID + '/tasks/' + data.id, {}, function(data){
      replaceTask(data, false);
      controller.JustRebind();
    });
  }

  updateRunningTimes() {
    var time_list = $('#running_times_menu ul li');
    var count = time_list.length;
    if (count > 0) {
      $('#running_times_count span').html('You have ' + count + ' running times');
      $('#running_times_count').show();
    } else {  
      $('#running_times_count').hide();
      $('#running_times_menu').hide();
      time_list.hide();
    }
  }

  bindDynamic() {

    var controller = this;

        // Popup form for Add Item
    this.bindDynamicEvent($('.addTask form'), 'submit', 
      (origEvt) => {
        var theForm = $(this);
        controller.startLoading(origEvt); 
        RailsCollabHelpers.request(theForm, (evt) => {
          controller.stopLoading(origEvt); 
          theForm.autofocus();

          // TODO: check error
          theForm.reset();

          // set task list back to edit mode when new task is added (otherwise new item will be in edit mode, and rest will be in reorder mode)
          //var list = theForm.parents('.taskList:first');
          //if (list.hasClass('reorder')) {
          //  theForm.find('.doEditTaskList').click();
          //}

          // Add content in the correct location
          theForm.parents('.taskList:first').find('.' + data.task_class + ' .taskItems').append(data.content);
          controller.JustRebind();
        }) 
      }
    );

    this.bindDynamicEvent($('.addTask form .cancel'), 'click', function(evt) {
      var addItemInner = $(evt.target).parents('.inner:first');
      var newItem = addItemInner.parents('.addTask:first').find('.newTask:first');

      addItemInner.hide();
      addItemInner.children('form')[0].reset();
      newItem.show();

      return false;
    });

    // Add Item link
    this.bindDynamicEvent($('.newTask a'), 'click', function(evt) {
      var newItem = $(evt.target.parentNode);
      var addItemInner = newItem.parents('.addTask:first').find('.inner:first');

      addItemInner.show();
      addItemInner.autofocus();
      newItem.hide();

      return false;
    });

    /*$('.taskItem form.editTaskItem')
    .bind('ajax:beforeSend', startLoading)
    .bind('ajax:complete', stopLoading)
    .bind('ajax:success',
      function(evt, data, status, xhr) {
        replaceTask(data, false);
        JustRebind();
        return false;
      });

    $('.taskItem form.editTaskItem .cancel')
    .bind('ajax:beforeSend', startLoadingForm)
    .bind('ajax:complete', stopLoadingForm)
    .bind('ajax:success',
      function(evt, data, status, xhr) {
        replaceTask(data, false);
        JustRebind();
        return false;
      });*/

    this.bindDynamicEvent($('.taskList .completion'), 'click', function(evt) {
      var el = $(evt.target);
      var url = el.next('a').attr('href');

      RailsCollabHelpers.put(url, {
        'task[completed]': evt.target.checked
      },
      function(data, status, xhr) {
        controller.replaceTask(data, false);
        controller.JustRebind();
        return false;
      },
      'json');

      return false;
    });

    this.bindDynamicEvent($('.taskList .taskEdit'), 'submit', 
      (origEvt) => {
        var theForm = $(this);
        controller.startLoading(origEvt); 
        RailsCollabHelpers.request(theForm, (evt) => {
          controller.stopLoading(origEvt); 
          controller.replaceTask(data, true);
          controller.JustRebind();
        }) 
      }
    );

    this.bindDynamicEvent($('.taskList .taskDelete'), 'submit', 
      (origEvt) => {
        var theForm = $(this);
        controller.startLoading(origEvt); 
        RailsCollabHelpers.request(theForm, (evt) => {
          controller.stopLoading(origEvt); 
          $('#task_item_' + data.id).remove();
        }) 
      }
    );

    this.bindDynamicEvent($('.doEditTaskList'), 'click', function(evt) {
      var el = $(this);
      var list = el.parents('.taskList:first');
      list.removeClass('reorder');

      list.find('.openTasks:first ul').sortable('destroy');
      list.find('.taskItemHandle').hide();

      el.hide();
      el.parent().children('.doSortTaskList').show();

      return false;
    });

    this.bindDynamicEvent($('.doSortTaskList'), 'click', function(evt) {
      var el = $(evt.target);
      var url = el.attr('href');
      var list = el.parents('.taskList:first');
      list.addClass('reorder');

      list.find('.openTasks:first ul').sortable({
        axis: 'y',
        handle: '.taskItemHandle .inner',
        opacity: 0.75,
        update: function(e, ui) {
          RailsCollabHelpers.post(url, list.find('.openTasks:first ul').sortable('serialize', {
            key: 'tasks[]'
          }));
        }
      });

      list.find('.taskItemHandle').show();

      el.hide();
      el.parent().children('.doEditTaskList').show();

      return false;
    });


        // Generic action form
    this.bindDynamicEvent($('#action_dialog form'), 'submit', function(evt) {
      var form = $(this);
      RailsCollabHelpers.request(form, RebindAction);

      form.find('.submit:first').attr('disabled', true);
      //form.reset();
      return false;
    });

    this.bindDynamicEvent($('#action_dialog a.cancel'), 'click', function(evt) {
      $('#action_dialog').hide();

      return false;
    });

        // Start & stop time
    this.bindDynamicEvent($('.startTime'), 'click', function(evt) {
      var el = $(this);
      RailsCollabHelpers.post(el.attr('href'), {
        'time[open_task_id]': el.attr('task_id'),
        'time[assigned_to_id]': controller.USER_ID,
      },
      function(data){
        controller.reloadTask(data.task, false);
        var listed_time = $('#listed_time_' + data.id);
        if (listed_time.length == 0)
          $('#running_times_menu ul').append(data.content);
        else
          listed_time.replaceWith(data.content);
        controller.updateRunningTimes();
        controller.JustRebind();
      });

      return false;
    });

    this.bindDynamicEvent($('.stopTime'), 'click', function(evt) {
      var el = $(this);
      RailsCollabHelpers.put(el.attr('href'), {
        'time[open_task_id]': el.attr('task_id'),
        'time[assigned_to_id]': controller.USER_ID,
      },
      function(data){
        controller.reloadTask(data.task, false);
        $('#listed_time_' + data.id).remove();
        controller.updateRunningTimes();
        controller.JustRebind();
      });

      return false;
    });
  }

  rebind () {
    this.clearDynamicEvents();
    this.bindDynamic();
  }

  JustReload(data) {
    window.location.reload();
  }

  JustRebind(data) {
    this.rebind();
  }

  RebindAction(data) {
    this.rebind();
    $('#action_dialog').hide();
  }

  rebindDynamic() {

    this.rebind();
  }

  permissions_form_project_select(id) {
    if ($('#projectPermissions' + id).attr('checked'))
      $('#projectPermissionsBlock' + id).show();
    else
      $('#projectPermissionsBlock' + id).hide();
  }

  permissions_form_project_select_company(id) {
    if ($('#projectCompany' + id).attr('checked'))
      $('#projectCompanyUsers' + id).show();
    else
      $('#projectCompanyUsers' + id).hide();
  }

  permissions_form_project_select_all(id) {
    var val = $('#projectPermissions' + id + 'All').attr('checked');

    // Select all items then!
    permissions_form_items.forEach(
      function(sel) {
        $('#projectPermission' + id + sel).attr('checked', val);
      });
  }

  permissions_form_project_select_item(id) {
    var do_all = true;

    // Check to see if everything has been selected
    permissions_form_items.forEach(
      function(sel) {
        if (!$('#projectPermission' + id + this).attr('checked'))
          do_all = false;
      });

    $('#projectPermissions' + id + 'All').attr('checked', do_all);
  }

  permissions_form_items_set(list) {
    this.permissions_form_items = list;
  }

    // Form form stuff
  form_form_update_action() {
    $('#projectFormActionSelectMessage').attr('disabled', !$('#projectFormActionAddComment').attr('checked'));
    $('#projectFormActionSelectTaskList').attr('disabled', !$('#projectFormActionAddTask').attr('checked'));
  }

    // User form stuff
  user_form_update_passwordgen() {
    if ($('#userFormGeneratePassword').attr('checked'))
      $('#userFormPasswordInputs').hide();
    else
      $('#userFormPasswordInputs').show();
  }

  file_form_select_revision() {
    if ($('#fileFormVersionChange').attr('checked'))
      $('#fileFormRevisionCommentBlock').show();
    else
      $('#fileFormRevisionCommentBlock').hide();
  }

  file_form_select_update() {
    if ($('#fileFormUpdateFile').attr('checked'))
      $('#updateFileForm').show();
    else
      $('#updateFileForm').hide();
  }

  file_form_attach_update_action() {
    $('#attachFormSelectFile').attr('disabled', !$('#attachFormExistingFile').attr('checked'));
    $('#attachFilesInput_1').attr('disabled', !$('#attachFormNewFile').attr('checked'));
  }

  file_form_attach_init(limit) {
    if (file_form_controls != null)
      return;

    file_form_controls = {
      'count': 1,
      'next_id': 2,
      'limit': limit
    };

    var add_button = document.createElement('button');
    add_button.setAttribute('type', 'button');
    add_button.setAttribute('id', 'attachFilesAdd');
    add_button.className = 'add_button';
    add_button.appendChild(document.createTextNode("Add file"));

    $('#attachFiles')[0].appendChild(add_button);

    $(add_button).click(file_form_attach_add);
  }

  file_form_attach_add() {
    // Check to see if we have reached the limit
    if (file_form_controls.count >= file_form_controls.limit)
      return;

    var cur_id = file_form_controls.next_id;

    var attach_div = document.createElement('div');
    attach_div.id = 'attachFiles' + '_' + cur_id;

    var file_input = document.createElement('input');
    file_input.id = 'attachFilesInput_' + '_' + cur_id;
    file_input.setAttribute('type', 'file');
    file_input.setAttribute('name', 'uploaded_files[]');

    var remove_button = document.createElement('button');
    remove_button.setAttribute('type', 'button');
    remove_button.className = 'remove_button';
    remove_button.appendChild(document.createTextNode("Remove"));

    $(remove_button).click(function(event) {
      file_form_attach_remove(cur_id);
    });

    attach_div.appendChild(file_input);
    attach_div.appendChild(remove_button);

    $('#attachFilesControls')[0].appendChild(attach_div);

    if (cur_id >= file_form_controls.limit)
      $('#attachFilesAdd').attr('disabled', true);

    file_form_controls.next_id += 1;
    file_form_controls.count += 1;
  }

  file_form_attach_remove(id) {
    $('#attachFiles_' + id).remove();
    $('#attachFilesAdd').attr('disabled', false);
    file_form_controls.count -= 1;
  }

  notify_form_select(company_id, id) {
    var do_all = true;

    // Check to see if everything has been selected
    this.notify_form_companies['company_' + company_id].users.forEach(
      function(sel) {
        if (!$('#notifyUser' + sel).attr('checked'))
          do_all = false;
      });

    $('#notifyCompany' + company_id).attr('checked', do_all);
  }

  notify_form_select_company(id) {
    var val = $('#notifyCompany' + id).attr('checked');

    this.notify_form_companies['company_' + id].users.forEach(
      function(sel) {
        $('#notifyUser' + sel).attr('checked', val);
      });
  }

  notify_form_set_company(id) {
    var count = 0;
    var users = this.notify_form_companies['company_' + id].users;

    users.forEach(
      function(sel) {
        if ($('#notifyUser' + sel).attr('checked'))
          count += 1;
      });

    if (count == users.length)
      $('#notifyCompany' + id).attr('checked', true);
  }
};

