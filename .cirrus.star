load("cirrus", "env", "http")


def on_build_failed(ctx):
    # Only send Slack notifications for failed cron builds[1]
    #
    # [1]: https://cirrus-ci.org/guide/writing-tasks/#cron-builds
    if "Cron" not in ctx.payload.data.build.changeMessageTitle:
        return

    resp = http.post(env.get("SLACK_WEBHOOK_URL"), headers={
        "Content-Type": "application/json",
    }, json_body={
        "text": "Build {build_id} (\"{change_message_title}\") failed on branch \"{branch_name}\" in repository \"{repository_name}\".".format(
            build_id=ctx.payload.data.build.id,
            change_message_title=ctx.payload.data.build.changeMessageTitle,
            branch_name=ctx.payload.data.build.branch,
            repository_name=ctx.payload.data.repository.name,
        ),
        "url": "https://cirrus-ci.com/build/{build_id}".format(
            build_id=ctx.payload.data.build.id,
        ),
    })

    if resp.status_code != 200:
        fail("failed to post message to Slack: got unexpected HTTP {}".format(resp.status_code))

    resp_json = resp.json()

    if resp_json["ok"] != True:
        fail("got error when posting message to Slack: {}".format(resp_json["error"]))
