jQuery.fn.extend({
    request: function(callback, type) {
        var el = $(this[0]);
        return jQuery.ajax({
            type: el.attr('method'),
            url: el.attr('action'),
            data: el.serialize(),
            success: callback,
            dataType: type
        });
    },

    autofocus: function() {
        var el = this.find('.autofocus:first')[0];
        if (el)
          el.focus();
    },

    fancyRemove: function() {
        this.slideUp(300,
        function(evt) {
            $(this).remove();
        });
    }
});

// jQuery object extensions
jQuery.extend({
    del: function(url, data, callback, type) {
        if (jQuery.isFunction(data)) {
            callback = data;
            data = {};
        }

        data = data == null ? {}: data;
        if (!data['_method'])
        {
            if (typeof data == 'string')
            data += '&_method=DELETE';
            else
            data['_method'] = 'DELETE';
        }

        return jQuery.ajax({
            type: "POST",
            url: url,
            data: data,
            success: callback,
            dataType: type
        });
    },

    put: function(url, data, callback, type) {
        if (jQuery.isFunction(data)) {
            callback = data;
            data = {};
        }

        data = data == null ? {}: data;
        if (!data['_method'])
        {
            if (typeof data == 'string')
            data += '&_method=PUT';
            else
            data['_method'] = 'PUT';
        }

        return jQuery.ajax({
            type: "POST",
            url: url,
            data: data,
            success: callback,
            dataType: type
        });
    }
});

// authenticity_token fix
$(document).ajaxSend(function(event, request, settings) {
    if (typeof(AUTH_TOKEN) == "undefined" || request.type == 'GET') return;
    settings.data = settings.data ? (settings.data + '&') : "";
    settings.data += "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
});

$(document).ready(function() {
    bindStatic();
    bindDynamic();
});

function bindStatic() {

    $('.flash_success, .flash_error').click(function(evt) {
        $(this).hide('slow');

        return false;
    });

    $('.ajax_action').click(function(evt) {
        $.get($(this).attr('href'), {},
        JustRebind, 'script');

        return false;
    });

    $('a#messageFormAdditionalTextToggle').click(function(evt) {
        $('#messageFormAdditionalText').toggle();
        $('#messageFormAdditionalTextExpand').toggle();
        $('#messageFormAdditionalTextCollapse').toggle();

        return false;
    });

    $('.taskCheckbox .completion').click(function(evt) {
        var el = $(evt.target);
        var url = el.next('a').attr('href');

        $.put(url, {
            'task[completed]': evt.target.checked
        },
        JustReload, 'script');

        return false;
    });

    $('.PopupMenuWidgetAttachTo').click(function(evt) {
        $(this).title = '';
        var menu = $('#' + this.id + '_menu');
        if (menu.is(':hidden')) {
          $('.PopupMenuWidgetDiv').hide();
        }
        menu.toggle();
    });
}

function startLoading(evt) {
    $(evt.target).addClass('loading')
    .find('input, select, textarea, button').attr('disabled', 'disabled');
}

function stopLoading(evt, evt2, evt3, evt4) {
    $(evt.target).removeClass('loading')
    .find('input, select, textarea, button').attr('disabled', null);
}

function startLoadingForm(evt) {
    $(evt.target).parents('form:first').addClass('loading')
    .find('input, select, textarea, button').attr('disabled', 'disabled');
}

function stopLoadingForm(evt) {
    $(evt.target).parents('form:first').removeClass('loading')
    .find('input, select, textarea, button').attr('disabled', null);
}

function replaceTask(data, content) {
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

function reloadTask(data) {
  $.get('/projects/' + PROJECT_ID + '/tasks/' + data.id, {}, function(data){
    replaceTask(data, false);
    JustRebind();
  }, 'json');
}

function updateRunningTimes() {
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

function bindDynamic() {

    // Popup form for Add Item
    $('.addTask form')
    .bind('ajax:beforeSend', startLoading)
    .bind('ajax:complete', function(evt){stopLoading(evt); $(evt.target).autofocus();})
    .bind('ajax:success',
    function(evt, data, status, xhr) {
        var form = $(evt.target);
        form[0].reset();

        // set task list back to edit mode when new task is added (otherwise new item will be in edit mode, and rest will be in reorder mode)
        var list = form.parents('.taskList:first');
        if (list.hasClass('reorder')) {
            list.find('.doEditTaskList').click();
        }

        // Add content in the correct location
        form.parents('.taskList:first').find('.' + data.task_class + ' .taskItems').append(data.content);
        JustRebind();
        return false;
    });

    $('.addTask form .cancel').click(function(evt) {
        var addItemInner = $(evt.target).parents('.inner:first');
        var newItem = addItemInner.parents('.addTask:first').find('.newTask:first');

        addItemInner.hide();
        addItemInner.children('form')[0].reset();
        newItem.show();

        return false;
    });

    // Add Item link
    $('.newTask a').click(function(evt) {
        var newItem = $(evt.target.parentNode);
        var addItemInner = newItem.parents('.addTask:first').find('.inner:first');

        addItemInner.show();
        addItemInner.autofocus();
        newItem.hide();

        return false;
    });

    $('.taskItem form.editTaskItem')
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
    });

    $('.taskList .completion').click(function(evt) {
        var el = $(evt.target);
        var url = el.next('a').attr('href');

        $.put(url, {
            'task[completed]': evt.target.checked
        },
        function(data, status, xhr) {
            replaceTask(data, false);
            JustRebind();
            return false;
        },
        'json');

        return false;
    });

    $('.taskList .taskEdit')
    .bind('ajax:beforeSend', startLoading)
    .bind('ajax:complete', stopLoading)
    .bind('ajax:success',
    function(evt, data, status, xhr) {
        replaceTask(data, true);
        JustRebind();
        return false;
    });

    $('.taskList .taskDelete')
    .bind('ajax:beforeSend', startLoading)
    .bind('ajax:complete', stopLoading)
    .bind('ajax:success',
    function(evt, data, status, xhr) {
        $('#task_item_' + data.id).remove();
        return false;
    });

    $('.doEditTaskList').click(function(evt) {
        var el = $(this);
        var list = el.parents('.taskList:first');
        list.removeClass('reorder');

        list.find('.openTasks:first ul').sortable('destroy');
        list.find('.taskItemHandle').hide();

        el.hide();
        el.parent().children('.doSortTaskList').show();

        return false;
    });

    $('.doSortTaskList').click(function(evt) {
        var el = $(evt.target);
        var url = el.attr('href');
        var list = el.parents('.taskList:first');
        list.addClass('reorder');

        list.find('.openTasks:first ul').sortable({
            axis: 'y',
            handle: '.taskItemHandle .inner',
            opacity: 0.75,
            update: function(e, ui) {
                $.post(url, list.find('.openTasks:first ul').sortable('serialize', {
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
    $('#action_dialog form').submit(function(evt) {
        var form = $(this);
        form.request(RebindAction, 'script');

        form.find('.submit:first').attr('disabled', true);
        //form.reset();
        return false;
    });

    $('#action_dialog a.cancel').click(function(evt) {
        $('#action_dialog').hide();

        return false;
    });

    // Start & stop time
    $('.startTime').click(function(evt) {
        var el = $(this);
        $.post(el.attr('href'), {
            'time[open_task_id]': el.attr('task_id'),
            'time[assigned_to_id]': LOGGED_USER_ID,
        },
        function(data){
          reloadTask(data.task, false);
          var listed_time = $('#listed_time_' + data.id);
          if (listed_time.length == 0)
            $('#running_times_menu ul').append(data.content);
          else
            listed_time.replaceWith(data.content);
          updateRunningTimes();
          JustRebind();
        }, 'json');

        return false;
    });

    $('.stopTime').click(function(evt) {
        var el = $(this);
        $.put(el.attr('href'), {
            'time[open_task_id]': el.attr('task_id'),
            'time[assigned_to_id]': LOGGED_USER_ID,
        },
        function(data){
          reloadTask(data.task, false);
          $('#listed_time_' + data.id).remove();
          updateRunningTimes();
          JustRebind();
        }, 'json');

        return false;
    });
}

function JustReload(data) {
    window.location.reload();
}

function JustRebind(data) {
    rebindDynamic();
}

function RebindAction(data) {
    rebindDynamic();
    $('#action_dialog').hide();
}

function rebindDynamic() {

    $('.addTask form').unbind();
    $('.addTask form .cancel').unbind();
    $('.newTask a').unbind();
    $('.taskItem form').unbind();
    $('.taskItem form .cancel').unbind();
    $('.taskList .completion').unbind();
    $('.taskList .taskEdit').unbind();
    $('.taskList .taskDelete').unbind();

    $('.doSortTaskList').unbind();
    $('.doEditTaskList').unbind();

    $('#action_dialog form').unbind();
    $('#action_dialog a.cancel').unbind();

    $('.startTime').unbind();
    $('.stopTime').unbind();

    bindDynamic();
}

var Project = {
    buildUrl: function(resource) {
        return ('/projects/' + PROJECT_ID + resource);
    },

    updateRunningTimes: function(size, locale) {
        $('#running_times_count span').html(locale);

        if (size > 0)
        $('#running_times_count').show();
        else {
            $('#running_times_count').hide();
            $('#running_times_menu').hide();
        }
    }
};

// Login form stuff
// Permissions form stuff
var permissions_form_items = [];

function permissions_form_project_select(id)
 {
    if ($('#projectPermissions' + id).attr('checked'))
    $('#projectPermissionsBlock' + id).show();
    else
    $('#projectPermissionsBlock' + id).hide();
}

function permissions_form_project_select_company(id)
 {
    if ($('#projectCompany' + id).attr('checked'))
    $('#projectCompanyUsers' + id).show();
    else
    $('#projectCompanyUsers' + id).hide();
}

function permissions_form_project_select_all(id)
 {
    var val = $('#projectPermissions' + id + 'All').attr('checked');

    // Select all items then!
    $.each(permissions_form_items,
    function() {
        $('#projectPermission' + id + this).attr('checked', val);
    });
}

function permissions_form_project_select_item(id)
 {
    var do_all = true;

    // Check to see if everything has been selected
    $.each(permissions_form_items,
    function() {
        if (!$('#projectPermission' + id + this).attr('checked'))
        do_all = false;
    });

    $('#projectPermissions' + id + 'All').attr('checked', do_all);
}

function permissions_form_items_set(list)
 {
    permissions_form_items = list;
}

// Form form stuff
function form_form_update_action()
 {
    $('#projectFormActionSelectMessage').attr('disabled', !$('#projectFormActionAddComment').attr('checked'));
    $('#projectFormActionSelectTaskList').attr('disabled', !$('#projectFormActionAddTask').attr('checked'));
}

// User form stuff
function user_form_update_passwordgen()
 {
    if ($('#userFormGeneratePassword').attr('checked'))
    $('#userFormPasswordInputs').hide();
    else
    $('#userFormPasswordInputs').show();
}

// File form stuff
var file_form_controls = null;

function file_form_select_revision()
 {
    if ($('#fileFormVersionChange').attr('checked'))
    $('#fileFormRevisionCommentBlock').show();
    else
    $('#fileFormRevisionCommentBlock').hide();
}

function file_form_select_update()
 {
    if ($('#fileFormUpdateFile').attr('checked'))
    $('#updateFileForm').show();
    else
    $('#updateFileForm').hide();
}

function file_form_attach_update_action()
 {
    $('#attachFormSelectFile').attr('disabled', !$('#attachFormExistingFile').attr('checked'));
    $('#attachFilesInput_1').attr('disabled', !$('#attachFormNewFile').attr('checked'));
}

function file_form_attach_init(limit)
 {
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

function file_form_attach_add()
 {
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

function file_form_attach_remove(id)
 {
    $('#attachFiles_' + id).remove();
    $('#attachFilesAdd').attr('disabled', false);
    file_form_controls.count -= 1;
}

// Notification form stuff (mainly for message posting)
var notify_form_companies = {};

function notify_form_select(company_id, id)
 {
    var do_all = true;

    // Check to see if everything has been selected
    $.each(notify_form_companies['company_' + company_id].users,
    function() {
        if (!$('#notifyUser' + this).attr('checked'))
        do_all = false;
    });

    $('#notifyCompany' + company_id).attr('checked', do_all);
}

function notify_form_select_company(id)
 {
    var val = $('#notifyCompany' + id).attr('checked');

    $.each(notify_form_companies['company_' + id].users,
    function() {
        $('#notifyUser' + this).attr('checked', val);
    });
}

function notify_form_set_company(id)
 {
    var count = 0;
    var users = notify_form_companies['company_' + id].users;

    $.each(users,
    function() {
        if ($('#notifyUser' + this).attr('checked'))
        count += 1;
    });

    if (count == users.length)
    $('#notifyCompany' + id).attr('checked', true);
}
