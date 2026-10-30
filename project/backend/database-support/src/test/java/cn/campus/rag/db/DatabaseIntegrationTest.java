package cn.campus.rag.db;

import cn.campus.rag.db.entity.Chunk;
import cn.campus.rag.db.entity.Document;
import cn.campus.rag.db.entity.User;
import cn.campus.rag.db.mapper.ChunkMapper;
import cn.campus.rag.db.mapper.DocumentMapper;
import cn.campus.rag.db.mapper.UserMapper;
import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.MybatisSqlSessionFactoryBuilder;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.concurrent.TimeUnit;
import org.apache.ibatis.datasource.unpooled.UnpooledDataSource;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.mindrot.jbcrypt.BCrypt;
import static org.junit.jupiter.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class DatabaseIntegrationTest {
    static String baseUrl;
    static String user;
    static String password;
    static SqlSessionFactory factory;

    static String required(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Missing " + name + "; run scripts/Test-Week1.ps1");
        }
        return value;
    }

    static Connection connect(String database) throws SQLException {
        Connection connection = DriverManager.getConnection(baseUrl, user, password);
        if (database != null) connection.setCatalog(database);
        return connection;
    }

    static void execute(Connection connection, String sql) throws SQLException {
        try (var statement = connection.createStatement()) { statement.execute(sql); }
    }

    // Migration examples contain no procedures, delimiters, or semicolons in literals.
    static void importSimpleSql(Connection connection, Path file) throws Exception {
        String sql = Files.readString(file, StandardCharsets.UTF_8).replaceAll("(?m)^\\s*--[^\\r\\n]*", "");
        for (String statement : sql.split(";")) {
            if (!statement.isBlank()) execute(connection, statement);
        }
    }

    static long count(Connection c, String table) throws SQLException {
        try (var s = c.createStatement(); var r = s.executeQuery("SELECT COUNT(*) FROM " + table)) {
            r.next(); return r.getLong(1);
        }
    }

    static void rejected(Connection c, int code, String sql) {
        SQLException failure = assertThrows(SQLException.class, () -> execute(c, sql));
        assertEquals(code, failure.getErrorCode(), failure.getMessage());
    }

    @BeforeAll
    static void initialize() throws Exception {
        baseUrl = required("RAG_TEST_URL"); user = required("RAG_TEST_USER"); password = required("RAG_TEST_PASSWORD");
        try (Connection c = connect(null)) {
            // No IF NOT EXISTS or DROP: refuse to reuse any preexisting test database.
            execute(c, "CREATE DATABASE rag_week1_test CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci");
            execute(c, "CREATE DATABASE rag_week1_restore CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci");
            c.setCatalog("rag_week1_test");
            importSimpleSql(c, Path.of("database/mysql/migrations/V001__initial.sql"));
            importSimpleSql(c, Path.of("database/mysql/seeds/V001__demo.sql"));
        }
        String dbUrl = baseUrl.replace("/?", "/rag_week1_test?");
        var source = new UnpooledDataSource("com.mysql.cj.jdbc.Driver", dbUrl, user, password);
        var config = new MybatisConfiguration();
        config.setMapUnderscoreToCamelCase(true);
        config.setEnvironment(new Environment("integration", new JdbcTransactionFactory(), source));
        config.addMapper(UserMapper.class);
        config.addMapper(DocumentMapper.class);
        config.addMapper(ChunkMapper.class);
        factory = new MybatisSqlSessionFactoryBuilder().build(config);
    }

    @Test @Order(1)
    void initialDataAndPasswords() throws Exception {
        try (Connection c = connect("rag_week1_test")) {
            assertEquals(2, count(c, "users"));
            assertEquals(8, count(c, "documents"));
            assertEquals(40, count(c, "chunks"));
        }
        try (SqlSession session = factory.openSession()) {
            User admin = session.getMapper(UserMapper.class).selectById(1L);
            User student = session.getMapper(UserMapper.class).selectById(2L);
            assertEquals("ADMIN", admin.role); assertEquals("USER", student.role);
            assertTrue(BCrypt.checkpw("DemoOnly-2026!", admin.passwordHash));
            assertTrue(BCrypt.checkpw("DemoOnly-2026!", student.passwordHash));
            assertFalse(BCrypt.checkpw("wrong", admin.passwordHash));
        }
    }

    @Test @Order(2)
    void usernameRoleAndPlaintextConstraints() throws Exception {
        try (Connection c = connect("rag_week1_test")) {
            rejected(c, 1062, "INSERT INTO users(username,password_hash,display_name) SELECT 'DEMO_ADMIN',password_hash,'duplicate' FROM users WHERE id=1");
            rejected(c, 3819, "UPDATE users SET username='   ' WHERE id=2");
            rejected(c, 3819, "UPDATE users SET password_hash='plaintext' WHERE id=2");
            rejected(c, 3819, "UPDATE users SET role='SUPERUSER' WHERE id=2");
            rejected(c, 3819, "UPDATE users SET enabled=2 WHERE id=2");
        }
    }

    @Test @Order(3)
    void documentAndChunkConstraints() throws Exception {
        try (Connection c = connect("rag_week1_test")) {
            rejected(c, 1452, "UPDATE chunks SET document_id=999999 WHERE id=1021");
            rejected(c, 1451, "DELETE FROM documents WHERE id=102");
            rejected(c, 1451, "DELETE FROM users WHERE id=1");
            rejected(c, 1062, "INSERT INTO chunks(document_id,chunk_no,section_path,content) VALUES(102,1,'duplicate','duplicate')");
            rejected(c, 3819, "UPDATE chunks SET content='  ' WHERE id=1021");
            rejected(c, 3819, "UPDATE chunks SET chunk_no=0 WHERE id=1021");
            rejected(c, 1048, "UPDATE documents SET title=NULL WHERE id=104");
            rejected(c, 3819, "UPDATE documents SET effective_to=effective_from WHERE id=104");
            rejected(c, 3819, "UPDATE documents SET status='EXPIRED' WHERE id=104");
            rejected(c, 3819, "UPDATE documents SET source_type='PUBLIC' WHERE id=104");
            rejected(c, 1062, "UPDATE documents SET version='2026' WHERE id=101");
            rejected(c, 1452, "UPDATE documents SET replaced_by=104 WHERE id=101");
        }
    }

    static TreeSet<Long> candidateDocuments(List<Map<String, Object>> rows) {
        var ids = new TreeSet<Long>();
        for (var row : rows) {
            assertNotNull(row.get("chunkId")); assertNotNull(row.get("sectionPath"));
            assertTrue(row.get("content").toString().startsWith("【虚构演示】"));
            ids.add(((Number) row.get("documentId")).longValue());
        }
        return ids;
    }

    @Test @Order(4)
    void currentCandidatesExcludeOldFutureRepealedExpiredAndDraft() {
        try (SqlSession s = factory.openSession()) {
            var mapper = s.getMapper(DocumentMapper.class);
            var rows = mapper.selectEffectiveCandidates(LocalDate.of(2026,10,30));
            assertEquals(15, rows.size());
            assertEquals(new TreeSet<>(List.of(102L,104L,107L)), candidateDocuments(rows));
            assertEquals(rows, mapper.selectEffectiveCandidates(LocalDate.of(2026,10,30)));
        }
    }

    @Test @Order(5)
    void effectiveDateIsInclusiveExpiryIsExclusive() {
        try (SqlSession s = factory.openSession()) {
            var mapper = s.getMapper(DocumentMapper.class);
            assertEquals(new TreeSet<>(List.of(102L,104L,106L,107L)),
                candidateDocuments(mapper.selectEffectiveCandidates(LocalDate.of(2026,10,29))));
            assertEquals(new TreeSet<>(List.of(102L,104L,107L)),
                candidateDocuments(mapper.selectEffectiveCandidates(LocalDate.of(2026,10,31))));
            var future = mapper.selectEffectiveCandidates(LocalDate.of(2026,11,1));
            assertEquals(new TreeSet<>(List.of(103L,104L,107L)), candidateDocuments(future));
            assertTrue(future.stream().anyMatch(r -> r.get("content").toString().contains("90分")));
            assertFalse(future.stream().anyMatch(r -> r.get("content").toString().contains("85分")));
        }
    }

    @Test @Order(6)
    void mapperCrudAndNullUpdates() {
        try (SqlSession s = factory.openSession(false)) {
            var documents = s.getMapper(DocumentMapper.class);
            var chunks = s.getMapper(ChunkMapper.class);
            Document d = new Document();
            d.documentKey="mapper-test"; d.title="【虚构演示】Mapper新增"; d.version="1";
            d.status="DRAFT"; d.effectiveFrom=LocalDate.of(2026,10,30);
            d.effectiveTo=LocalDate.of(2026,12,1); d.sourceType="SYNTHETIC"; d.sourceNote="映射测试"; d.createdBy=1L;
            assertEquals(1, documents.insert(d)); assertNotNull(d.id);
            Document stored = documents.selectById(d.id);
            assertEquals(d.title, stored.title); assertEquals(d.effectiveFrom, stored.effectiveFrom);
            assertNotNull(stored.createdAt);
            Chunk chunk = new Chunk(); chunk.documentId=d.id; chunk.chunkNo=1;
            chunk.sectionPath="第一章/第一条"; chunk.content="【虚构演示】中文与emoji 🎓";
            assertEquals(1, chunks.insert(chunk));
            assertEquals(chunk.content, chunks.selectById(chunk.id).content);
            chunk.content="【虚构演示】编辑后";
            assertEquals(1, chunks.updateById(chunk));
            assertEquals(chunk.content, chunks.selectById(chunk.id).content);
            assertEquals(1, documents.update(null, new UpdateWrapper<Document>().eq("id",d.id).set("effective_to",null)));
            assertNull(documents.selectById(d.id).effectiveTo);
            assertEquals(1, chunks.deleteById(chunk.id));
            assertEquals(1, documents.deleteById(d.id));
            s.rollback();
        }
    }

    @Test @Order(7)
    void userMapperDefaultRoleAndRollback() {
        try (SqlSession s = factory.openSession(false)) {
            User u = new User(); u.username="new-student"; u.displayName="新学生";
            u.passwordHash=BCrypt.hashpw("Temporary!",BCrypt.gensalt(4));
            var mapper=s.getMapper(UserMapper.class);
            assertEquals(1,mapper.insert(u));
            assertEquals("USER",mapper.selectById(u.id).role);
            assertEquals(1,mapper.deleteById(u.id));
            s.rollback();
        }
    }

    @Test @Order(8)
    void familyLocksSerializeRevisionAndRollbackPreservesState() throws Exception {
        try (SqlSession s = factory.openSession(false); Connection other=connect("rag_week1_test")) {
            assertEquals(3,s.getMapper(DocumentMapper.class).lockVersionFamily("scholarship").size());
            execute(other,"SET SESSION innodb_lock_wait_timeout=1");
            assertTimeout(Duration.ofSeconds(5), () -> rejected(other,1205,"UPDATE documents SET title='blocked' WHERE id=102"));
            s.getMapper(DocumentMapper.class).update(null,new UpdateWrapper<Document>().eq("id",102L).set("title","临时修改"));
            s.rollback();
        }
        try (SqlSession s=factory.openSession()) {
            assertTrue(s.getMapper(DocumentMapper.class).selectById(102L).title.contains("本科生奖学金"));
        }
    }

    @Test @Order(9)
    void sqlExamplesRunAndRollback() throws Exception {
        try (Connection c=connect("rag_week1_test")) {
            importSimpleSql(c,Path.of("database/mysql/queries/01__effective_candidates.sql"));
            importSimpleSql(c,Path.of("database/mysql/queries/02__crud_examples.sql"));
            importSimpleSql(c,Path.of("database/mysql/queries/03__version_transaction.sql"));
            importSimpleSql(c,Path.of("database/mysql/queries/04__integrity_and_indexes.sql"));
            assertEquals(8,count(c,"documents")); assertEquals(40,count(c,"chunks"));
        }
    }

    @Test @Order(10)
    void noOrphansNoOverlappingIntervalsAndCorrectSuccessorDates() throws Exception {
        List<String> checks=List.of(
            "SELECT c.id FROM chunks c LEFT JOIN documents d ON c.document_id=d.id WHERE d.id IS NULL",
            "SELECT a.id FROM documents a JOIN documents b ON a.replaced_by=b.id WHERE a.document_key<>b.document_key OR a.effective_to<>b.effective_from OR a.effective_from>=b.effective_from",
            "SELECT a.id FROM documents a JOIN documents b ON a.document_key=b.document_key AND a.id<b.id WHERE a.status='ACTIVE' AND b.status='ACTIVE' AND a.effective_from<COALESCE(b.effective_to,'9999-12-31') AND b.effective_from<COALESCE(a.effective_to,'9999-12-31')");
        try (Connection c=connect("rag_week1_test")) {
            for(String sql:checks) try(var s=c.createStatement();var r=s.executeQuery(sql)) { assertFalse(r.next(),sql); }
        }
    }

    @Test @Order(11)
    void indexesExistAndExplainCanExecute() throws Exception {
        try (Connection c=connect("rag_week1_test");var s=c.createStatement()) {
            try(var r=s.executeQuery("SHOW INDEX FROM documents WHERE Key_name='idx_documents_effective'")) { assertTrue(r.next()); }
            try(var r=s.executeQuery("SHOW INDEX FROM chunks WHERE Key_name='uq_chunks_document_no'")) { assertTrue(r.next()); }
            try(var r=s.executeQuery("EXPLAIN SELECT c.id FROM documents d JOIN chunks c ON c.document_id=d.id WHERE d.status='ACTIVE' AND d.effective_from<='2026-10-30' AND (d.effective_to IS NULL OR d.effective_to>'2026-10-30')")) {
                assertTrue(r.next());
            }
        }
    }

    static void runClient(String executable, List<String> arguments, Path input) throws Exception {
        var command=new ArrayList<String>();
        command.add(Path.of(required("RAG_MYSQL_BIN"),executable).toString());
        command.add("--defaults-extra-file="+required("RAG_MYSQL_OPTIONS"));
        command.addAll(arguments);
        var builder=new ProcessBuilder(command).redirectError(ProcessBuilder.Redirect.INHERIT).redirectOutput(ProcessBuilder.Redirect.INHERIT);
        if(input!=null) builder.redirectInput(input.toFile());
        Process process=builder.start();
        if(!process.waitFor(60,TimeUnit.SECONDS)) { process.destroyForcibly(); fail(executable+" timed out"); }
        assertEquals(0,process.exitValue(),executable);
    }

    static List<List<String>> rows(Connection c,String table) throws SQLException {
        var result=new ArrayList<List<String>>();
        try(var s=c.createStatement();ResultSet r=s.executeQuery("SELECT * FROM "+table+" ORDER BY id")) {
            int columns=r.getMetaData().getColumnCount();
            while(r.next()) {
                var row=new ArrayList<String>();
                for(int i=1;i<=columns;i++) row.add(r.getString(i));
                result.add(row);
            }
        }
        return result;
    }

    @Test @Order(12)
    void snapshotRestoresAllColumnsAndIsQueryable() throws Exception {
        Path snapshot=Path.of(required("RAG_SNAPSHOT"));
        runClient("mysqldump.exe",List.of("--single-transaction","--no-tablespaces","--set-gtid-purged=OFF","--skip-comments","--result-file="+snapshot,"rag_week1_test"),null);
        assertTrue(Files.size(snapshot)>1000);
        runClient("mysql.exe",List.of("rag_week1_restore"),snapshot);
        try(Connection source=connect("rag_week1_test");Connection restored=connect("rag_week1_restore")) {
            for(String table:List.of("users","documents","chunks")) assertEquals(rows(source,table),rows(restored,table),table);
            try(var s=restored.createStatement();var r=s.executeQuery("SELECT COUNT(*) FROM documents d JOIN chunks c ON c.document_id=d.id WHERE d.status='ACTIVE' AND d.effective_from<='2026-10-30' AND (d.effective_to IS NULL OR d.effective_to>'2026-10-30')")) {
                r.next(); assertEquals(15,r.getInt(1));
            }
        }
    }

    @Test @Order(13)
    void managementScriptInitializationAndRestoreMatchSeed() throws Exception {
        try(Connection source=connect("campus_rag_week1_cli");Connection restored=connect("campus_rag_week1_cli_restored")) {
            assertEquals(2,count(source,"users"));
            assertEquals(8,count(source,"documents"));
            assertEquals(40,count(source,"chunks"));
            for(String table:List.of("users","documents","chunks")) assertEquals(rows(source,table),rows(restored,table),table);
            try(var s=restored.createStatement();var r=s.executeQuery("SELECT content FROM chunks WHERE id=1022")) {
                assertTrue(r.next());
                assertEquals("【虚构演示】奖学金申请需平均成绩不低于85分，仅适用于2026版。",r.getString(1));
            }
        }
    }
}
