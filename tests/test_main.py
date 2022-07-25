import demo.main


class TestMain:
    def mock_db_read_demo_table():
        result = []
        for i in range(1, 3):
            item = {"id": i, "description": f"test{i}"}
            result.append(item)
        return result

    def test_read_rds(_, mocker):
        # arrange
        mocker.patch("demo.main.db.read_demo_table", TestMain.mock_db_read_demo_table)
        spy_db_read_demo_table = mocker.spy(demo.main.db, "read_demo_table")

        # act
        result = demo.main.read_rds()

        # assert
        spy_db_read_demo_table.assert_called_once_with()
        assert result is not None
        assert (
            result
            == """[{"id": 1, "description": "test1"}, {"id": 2, "description": "test2"}]"""
        )
